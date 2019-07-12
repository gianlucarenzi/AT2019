/*This source code copyrighted by Lazy Foo' Productions (2004-2013)
and may not be redistributed without written permission.*/

//The headers
#include "SDL/SDL.h"
#include "SDL/SDL_image.h"
#include <string>

//Screen attributes
const int SCREEN_WIDTH = 240;
const int SCREEN_HEIGHT = 320;
const int SCREEN_BPP = 8;

//The surfaces
SDL_Surface *background = NULL;
SDL_Surface *sprites = NULL;
SDL_Surface *framebuffer = NULL;

//The event structure
static SDL_Event event;

static SDL_Surface *load_image( const char *filename )
{
    //The image that's loaded
    SDL_Surface* loadedImage = NULL;

    //The optimized image that will be used
    SDL_Surface* optimizedImage = NULL;

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
			#define COLORKEY_R 0x00
			#define COLORKEY_G 0xFF
			#define COLORKEY_B 0xFF

            //Map the color key
            Uint32 colorkey = SDL_MapRGB( optimizedImage->format, COLORKEY_R, COLORKEY_G, COLORKEY_B );

            //Set all pixels of color R 0, G 0xFF, B 0xFF to be transparent
            SDL_SetColorKey( optimizedImage, SDL_SRCCOLORKEY, colorkey );
        }
    }

    //Return the optimized image
    return optimizedImage;
}

void apply_surface( int x, int y, SDL_Surface* source, SDL_Surface* destination )
{
    //Temporary rectangle to hold the offsets
    SDL_Rect offset;

    //Get the offsets
    offset.x = x;
    offset.y = y;

    //Blit the surface
    SDL_BlitSurface( source, NULL, destination, &offset );
}

bool init()
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

bool load_files(void)
{
    //Load the background image
    background = load_image( "background.png" );

    //If the background didn't load
    if( background == NULL )
    {
        return false;
    }

    //Load the stick figure
    sprites = load_image( "foo.png" );

    //If the stick figure didn't load
    if( sprites == NULL )
    {
        return false;
    }

    return true;
}

void clean_up()
{
    //Free the surfaces
    SDL_FreeSurface( background );
    SDL_FreeSurface( sprites );

    //Quit SDL
    SDL_Quit();
}

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
    if( load_files() == false )
    {
        return 1;
    }

    //Apply the surfaces to the screen
    apply_surface( 0, 0, background, framebuffer );
    apply_surface( 120, 80, foo, framebuffer );

    //Update the screen
    if( SDL_Flip( framebuffer ) == -1 )
    {
        return 1;
    }

    //While the user hasn't quit
    while( quit == false )
    {
        //While there's events to handle
        while( SDL_PollEvent( &event ) )
        {
            //If the user has Xed out the window
            if( event.type == SDL_QUIT )
            {
                //Quit the program
                quit = true;
            }
        }
    }

    //Free the surfaces and quit SDL
    clean_up();

    return 0;
}
