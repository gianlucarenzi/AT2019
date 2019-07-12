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

//Screen attributes
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

static char colormap[256][3] = {
	{  0,  0,  0},
	{  0,  0,149},
	{252,252,255},
	{250,  0,  0},
	{255,  0,255},
	{  5,  5,  5},
	{  0,255,255},
	{  0,115,247},
	{255,228,172},
	{248,248,248},
	{155,186,  0},
	{112,112,  0},
	{  0, 39,  0},
	{251,186,153},
	{112, 39,  0},
	{ 39, 78,  0},
	{  0,126,164},
	{  0,210,210},
	{  0, 61,128},
	{185, 94,  2},
	{  0,186,255},
	{  0,149,198},
	{252,252,252},
	{248,184,  0},
	{255,255,255},
	{186,155,  0},
	{251,154,  0},
	{  0,250,  0},
	{251,186,255},
	{154, 78,255},
	{153,  0,  0},
	{250, 78,  0},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255},
	{255,255,255}
};

//The surfaces
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

INTERNALRAM t_sprite objects[32];
static int fdfifo = -1;
static int retrobit_video_card_ready = 0;

//The event structure
static SDL_Event event;

/**
static SDL_Surface *load_image( const char *filename )
{
	//The optimized image that will be used
	SDL_Surface* optimizedImage = NULL;

	//The image that's loaded
	SDL_Surface* loadedImage = NULL;

	//Load the image
	loadedImage = IMG_Load( filename );

	//If the image loaded
	if( loadedImage != NULL )
	{
		//Create an optimized image
		optimizedImage = SDL_DisplayFormat( loadedImage );

		//Free the old image
		SDL_FreeSurface( loadedImage );

		//If the image was optimized just fine
		if( optimizedImage != NULL )
		{
			//Map the color key
			Uint32 colorkey = SDL_MapRGB( optimizedImage->format, COLORKEY_R, COLORKEY_G, COLORKEY_B );

			//Set all pixels of color R 0, G 0xFF, B 0xFF to be transparent
			SDL_SetColorKey( optimizedImage, SDL_SRCCOLORKEY, colorkey );
		}
	}

	//Return the optimized image
	return optimizedImage;
}
**/
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


static int video_card_initialize_fifo(void)
{
	char * myfifo = "/tmp/rblvfifo";
	int rval = 0;

	if (fdfifo < 0)
	{
		printf("video_card_initialize_fifo() Opening for READING\n");
		fdfifo = open(myfifo, O_RDONLY);

		if (fdfifo < 0) {
			rval = 1;
		} else {
			printf("video_card_initialize_fifo() READY\n");
		}
	}

	return rval;
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

	SDL_Color colors[256];
	// Fill colors with color information
	for (i = 0; i < 256; i++)
	{
		colors[i].r = colormap[i][0]; // R
		colors[i].g = colormap[i][1]; // G
		colors[i].b = colormap[i][2]; // B
	}

	// Sprites & Background uses the same colormap
	SDL_SetColors(background, colors, 0, 256);
	SDL_SetColors(sprites, colors, 0, 256);

	// Now sprites all blacks
	memset((uint8_t *) sprites->pixels, 0x00, 32 * 1024); // 32K
	// Black screen
	memset((uint8_t *) background->pixels, 0x00, (SCREEN_WIDTH * SCREEN_HEIGHT));

	//Map the color key
	uint32_t colorkey = SDL_MapRGB(sprites->format, COLORKEY_R, COLORKEY_G, COLORKEY_B );
	SDL_SetColorKey(sprites, SDL_SRCCOLORKEY, colorkey );
	return video_card_initialize_fifo() == 0 ? true : false;
}

void clean_up(void)
{
	//Free the surfaces
	SDL_FreeSurface( background );
	SDL_FreeSurface( sprites );
	//Quit SDL
	SDL_Quit();
}


/**
static int create_sprite(int index)
{
	SDL_Surface *surf;
	// Every Sprite has an unique area allocated!
	uint32_t * ptr = sprites->pixels;
	int offs = SPRITE_HEIGHT * SPRITE_WIDTH * index;
	printf("SPRITE: %d -- PTR: %p -- OFFSET: %d\n\r", index, ptr, offs);
	surf = SDL_CreateRGBSurface(SDL_SWSURFACE, SPRITE_WIDTH, SPRITE_HEIGHT,
		SCREEN_BPP, rmask, gmask, bmask, amask);
	if (surf == NULL)
		return -1;

	objects[ index ].surface = SDL_DisplayFormat(surf);
	SDL_Color colors[256];
	// Fill colors with color information
	for (int i = 0; i < 256; i++)
	{
		colors[i].r = colormap[i][0]; // R
		colors[i].g = colormap[i][1]; // G
		colors[i].b = colormap[i][2]; // B
	}

	// Sprites & Background uses the same colormap
	SDL_SetColors(objects[ index ].surface, colors, 0, 256);
	// and the same color key
	uint32_t colorkey = SDL_MapRGB(objects[ index ].surface->format,
		COLORKEY_R, COLORKEY_G, COLORKEY_B );
	SDL_SetColorKey(objects[ index ].surface, SDL_SRCCOLORKEY, colorkey );

	uint32_t * dst = objects[ index ].surface->pixels;

	// Now the sprite #index has been created!
	memcpy(dst, ptr + offs, SPRITE_WIDTH * SPRITE_HEIGHT);

	objects[index].is_visible = 1;
	return 0;
}


static void put_sprite(int index, int x, int y)
{
	apply_surface(x, y, objects[index].surface, framebuffer);
	SDL_Flip(framebuffer);
}


static int mario_is_jumping = 0;

static void mario_walk(int x, int y)
{
	static int currFrame = 0;
	uint8_t framesAnim[4] = { 1, 2, 3, 2 };
	if (! mario_is_jumping)
	{
			// Mario is walking from sprite 1 to 4 and downto 1
		printf("MARIO WALK: IDX: %d\r\n", framesAnim[ currFrame ]);
		put_sprite(framesAnim[ currFrame ], x, y);
		if (currFrame < 4)
			currFrame++;
		else
			currFrame=0;
	}
}


static void mario_stop(int x, int y)
{
	if (! mario_is_jumping)
	{
		printf("MARIO STOP\r\n");
		put_sprite(0, x, y);
	}
}

typedef struct {
	int jx;
	int jy;
} t_jump;

static int mario_jump(int x, int y)
{
	static int frame = 0;
	t_jump table[16] = {
		[0] = {
			.jx = 0,
			.jy = 0,
		},
		[1] = {
			.jx = 1,
			.jy = 0,
		},
		[2] = {
			.jx = 2,
			.jy = 0,
		},
		[3] = {
			.jx = 4,
			.jy = 0,
		},
		[4] = {
			.jx = 8,
			.jy = 0,
		},
		[5] = {
			.jx = 16,
			.jy = 0,
		},
		[6] = {
			.jx = 32,
			.jy = 0,
		},
		[7] = {
			.jx = 48,
			.jy = 0,
		},
		[8] = {
			.jx = 64,
			.jy = 0,
		},
		[9] = {
			.jx = 48,
			.jy = 0,
		},
		[10] = {
			.jx = 32,
			.jy = 0,
		},
		[11] = {
			.jx = 16,
			.jy = 0,
		},
		[12] = {
			.jx = 8,
			.jy = 0,
		},
		[13] = {
			.jx = 4,
			.jy = 0,
		},
		[14] = {
			.jx = 2,
			.jy = 0,
		},
		[15] = {
			.jx = 1,
			.jy = 0,
		},
	};

	if (! mario_is_jumping)
	{
		printf("MARIO WAS NOT JUMPING! NOW JUMPS\r\n");
		mario_is_jumping = 1;
	}

	if (mario_is_jumping)
	{
		// ROTATED!
		printf("MARIO JUMPING\r\n");
		put_sprite(4, table[ frame ].jx + x, table[ frame ].jy + y);
		if (frame < 16)
			frame++;
		else
		{
			frame=0;
			mario_is_jumping = 0;
		}
	}

	return mario_is_jumping;
}
**/
#include <sys/time.h>

int main( int argc, char* args[] )
{
	//Quit flag
	bool quit = false;

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
		uint8_t buffer[256];
		int r = read(fdfifo, buffer, 256);
		if (r > 0)
		{
/**
	poke(0xd501, 0xff); // # of colors for background $D501
	for (l = 0; l <= 0xff; l++)
		poke(0xd502, colormap[l]); // $D501 autoincrement address for palette

	poke(0xd503, 0xff); // colormap for sprite $D503
	for (l = 0; l <= 0xff; l++)
		poke(0xd504, spritecolormap[l]); // $D504 autoincrement address for palette

	poke(0xd504, 64);   // sprite is 64x64
	for (l = 0; l < 64; l++)
		poke(0xd505, spritedata[l]);

	int x = 100;
	int y = 100;
	poke(0xd506, x); // sprite position
	poke(0xd507, y);

 **/
			numcolors_background = buffer[1];
			colormap[
//			printf("R %d DATA received\n", r);

//			for (int i = 0; i < 256; i++)
//			{
//				printf("%02X ", (uint8_t) buffer[i]);
//				if (i % 16 == 0)
//					printf("\n");
//			}
//			printf("\n");
//			apply_surface(0, 0, background, framebuffer);
		}
	}

	//Free the surfaces and quit SDL
	clean_up();

	return 0;
}
