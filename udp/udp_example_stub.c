
/*
** Compile this file as follows:
**  $ gcc -std=c99 -I$HOME/mruby/include udp_example_stub.c -o udp_example $HOME/mruby/build/host/lib/libmruby.a -lm
*/
#include <mruby.h>
#include <mruby/irep.h>

#include "udp_example.c"

int
main(void)
{
  mrb_state *mrb = mrb_open();

  if (!mrb) { 
    /* handle error */ 
    printf("%s", "Error calling mrb_open()\n");
  }

  mrb_load_irep(mrb, udp_example_symbol);
  mrb_close(mrb);
  return 0;
}
