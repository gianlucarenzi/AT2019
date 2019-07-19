#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "SDL/SDL.h"
#include "SDL/SDL_image.h"
#include "SDL/SDL_thread.h"
#include <sys/time.h>

const int SCREEN_WIDTH = 320;
const int SCREEN_HEIGHT = 240;
const int SCREEN_BPP = 8;

#define COLORKEY_R 0xFF
#define COLORKEY_G 0x00
#define COLORKEY_B 0xFF

static 	uint32_t
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
	rmask = 0xff000000,
	gmask = 0x00ff0000,
	bmask = 0x0000ff00,
	amask = 0x000000ff;
#else
	rmask = 0x000000ff,
	gmask = 0x0000ff00,
	bmask = 0x00ff0000,
	amask = 0xff000000;
#endif

#define INTERNALRAM

/* From MCU */
INTERNALRAM SDL_Surface *background = NULL;
INTERNALRAM SDL_Surface *sprites = NULL;

/* Internal */
INTERNALRAM SDL_Surface *framebuffer = NULL;

typedef struct {
	SDL_Surface * surface;
	int x;
	int y;
	int is_visible;
} t_sprite;

typedef enum {
	TBACKGROUND = 0,
	TSPRITES,
	TNULL,
} t_object;

INTERNALRAM t_sprite objects[32];
static int fdfifow = -1;
static int retrobit_video_card_ready_w = 0;
static int fdfifor = -1;
static int retrobit_video_card_ready_r = 0;

typedef struct {
	uint8_t address;
	uint8_t data;
} t_ataribus;

static t_ataribus writebus[1];
static t_ataribus readbus[1];

static uint8_t regmap_read[256];
static uint8_t regmap_write[256];

//Quit flag
static bool quit = false;

//The thread that will be used
static SDL_Thread *thread = NULL;

//The event structure
static SDL_Event event;

static void apply_surface( int x, int y, SDL_Surface* source, SDL_Surface* destination )
{
	//Temporary rectangle to hold the offsets
	SDL_Rect offset;

	//Get the offsets
	offset.x = x;
	offset.y = y;

	//Blit the surface
	SDL_BlitSurface( source, NULL, destination, &offset );
	SDL_Flip(framebuffer);
}

static bool init()
{
	//Initialize all SDL subsystems
	if( SDL_Init( SDL_INIT_EVERYTHING ) == -1 )
	{
		return 1;
	}

	//Set up the screen
	framebuffer = SDL_SetVideoMode( SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, SDL_SWSURFACE );

	//If there was an error in setting up the screen
	if( framebuffer == NULL )
	{
		return 1;
	}

	//Set the window caption
	SDL_WM_SetCaption( "ATARI ABEX BUS VIDEO CARD READY", NULL );

	//If everything initialized fine
	return true;
}


static int video_card_initialize_fifo_r(void)
{
	char * myfifo = "/tmp/rblvfifow";
	int rval = 0;

	if (fdfifor < 0)
	{
		printf("video_card_initialize fifo() from MCU READING\n");
		fdfifor = open(myfifo, O_RDONLY);

		if (fdfifor < 0) {
			rval = 1;
		} else {
			printf("video_card_initialize fifo() from MCU READY\n");
		}
	}

	return rval;
}

static int video_card_initialize_fifo_w(void)
{
	char * myfifo = "/tmp/rblvfifor";
	int rval = 0;

	if (fdfifow < 0)
	{
		printf("video_card_initialize fifo() to MCU WRITING\n");
		fdfifow = open(myfifo, O_WRONLY);

		if (fdfifow < 0) {
			rval = 1;
		} else {
			printf("video_card_initialize fifo() to MCU READY\n");
		}
	}

	return rval;
}

static int video_card_initialize_fifo(void)
{
	int rval = video_card_initialize_fifo_r();
	rval |= video_card_initialize_fifo_w();
	return rval;
}

static uint8_t colormap[256][3];

static void set_color_map(t_object obj)
{
	int i;
	SDL_Color colors[256];
	// Fill colors with color information
	for (i = 0; i < 256; i++)
	{
		colors[i].r = colormap[i][0]; // R
		colors[i].g = colormap[i][1]; // G
		colors[i].b = colormap[i][2]; // B
	}

	switch( obj )
	{
		case TBACKGROUND:
			SDL_SetColors(background, colors, 0, 256);
			break;
		case TSPRITES:
			SDL_SetColors(sprites, colors, 0, 256);
			break;
	}
}

bool init_video_card(void)
{
	int i;
	SDL_Surface *surf;
	// Allocate surface for background and sprites
	surf = SDL_CreateRGBSurface(SDL_SWSURFACE, SCREEN_WIDTH,
		SCREEN_HEIGHT, SCREEN_BPP, rmask, gmask, bmask, amask);
	if (surf == NULL)
		return false;
	background = SDL_DisplayFormat(surf);

	surf = SDL_CreateRGBSurface(SDL_SWSURFACE, 32, 1024, SCREEN_BPP,
		rmask, gmask, bmask, amask);
	if (surf == NULL)
		return false;

	sprites = SDL_DisplayFormat(surf);

	// Now sprites all blacks
	memset((uint8_t *) sprites->pixels, 0x00, 32 * 1024); // 32K
	// Black screen
	memset((uint8_t *) background->pixels, 0x00, (SCREEN_WIDTH * SCREEN_HEIGHT));

	//Map the color key for sprites
	uint32_t colorkey = SDL_MapRGB(sprites->format, COLORKEY_R, COLORKEY_G, COLORKEY_B );
	SDL_SetColorKey(sprites, SDL_SRCCOLORKEY, colorkey );
	return video_card_initialize_fifo() == 0 ? true : false;
}

void clean_up(void)
{
	SDL_KillThread( thread );
	//Free the surfaces
	SDL_FreeSurface( background );
	SDL_FreeSurface( sprites );
	//Quit SDL
	SDL_Quit();
}

static int writeToMCU(void *data)
{
	bool towrite = 0;
	int r;
	printf("%s thread Running...\n", __FUNCTION__ );
	while ( quit == false)
	{
		static uint8_t addr;
		static uint8_t data;
		if (readbus[0].address != addr)
		{
			printf("%s ADDR Changed from %d to %d\n", __FUNCTION__, addr, readbus[0].address);
			addr = readbus[0].address;
			towrite = 1;
		}
		if (readbus[0].data != data)
		{
			printf("%s DATA Changed from %d to %d\n", __FUNCTION__, data, readbus[0].data);
			data = readbus[0].data;
			towrite = 1;
		}
		if (towrite)
		{
			r = write(fdfifow, readbus, sizeof(t_ataribus));
		}
		//SDL_Delay(100);
	}
	return 0;
}

int main( int argc, char* args[] )
{
	//Initialize
	if( init() == false )
	{
		return 1;
	}

	//Load the files
	if( init_video_card() == false )
	{
		return 1;
	}

	thread = SDL_CreateThread( writeToMCU, NULL );

	//Apply the surfaces to the screen
	apply_surface( 0, 0, background, framebuffer);
	//apply_surface( 10, 10, sprites, framebuffer );

	//Update the screen
	if( SDL_Flip( framebuffer ) == -1 )
	{
		return 1;
	}

	printf("VIDEO CARD READY\n");
	int counter = 0;
	uint8_t * ptr = (uint8_t *) background->pixels;

	//While the user hasn't quit
	while( quit == false )
	{
		//While there's events to handle
		while( SDL_PollEvent( &event ) )
		{
			switch( event.type )
			{
				case SDL_QUIT:
					//Quit the program
					quit = true;
					break;
				case SDL_KEYDOWN:
					switch( event.key.keysym.sym )
					{
						case SDLK_LEFT:

							break;
						case SDLK_RIGHT:
							break;
						case SDLK_UP:
							break;
						default:
							break;
					}
					break;
				case SDL_KEYUP:
					break;
			}
		}
		// Read from MCU
		int r = read(fdfifor, writebus, sizeof(t_ataribus));
		if (r > 0)
		{
			readbus[0].address = writebus[0].address;
			readbus[0].data = writebus[0].data;
//			apply_surface(0, 0, background, framebuffer);
			printf("ADDR: $D5%02X -- DATA: $%02X\n", writebus[0].address, writebus[0].data);
		}
	}

	//Free the surfaces and quit SDL
	clean_up();

	return 0;
}
