#*=====================================================================*/
#*    serrano/prgm/project/bigloo/examples/Roman/Makefile              */
#*    -------------------------------------------------------------    */
#*    Author      :  Manuel Serrano                                    */
#*    Creation    :  Tue Jan 30 15:19:19 1996                          */
#*    Last change :  Sun Jul  9 10:24:41 2017 (serrano)                */
#*    Copyright   :  1996-2017 Manuel Serrano, see LICENSE file        */
#*    -------------------------------------------------------------    */
#*    The makefile to build roman                                      */
#*=====================================================================*/

#*---------------------------------------------------------------------*/
#*    The default configuration                                        */
#*---------------------------------------------------------------------*/
include ../../Makefile.buildconfig
include ../../Makefile.config

#*---------------------------------------------------------------------*/
#*    flags                                                            */
#*---------------------------------------------------------------------*/
BIGLOO          = $(BOOTBINDIR)/bigloo
BGLOPTFLAGS	= -O +rm
BFLAGS		= $(BGLOPTFLAGS)
DEST		= roman

#*---------------------------------------------------------------------*/
#*    Objects and sources                                              */
#*---------------------------------------------------------------------*/

#*--- scm -------------------------------------------------------------*/
SCM_FILE	= roman

SCM_OBJ		= $(SCM_FILE:%=%.o)
SCM_SRC		= $(SCM_OBJ:%.o=%.scm)

#*---------------------------------------------------------------------*/
#*    All objects and sources                                          */
#*---------------------------------------------------------------------*/
OBJ		= $(C_OBJ) $(SCM_OBJ)
SRC		= $(C_SRC) $(SCM_SRC)

POPULATION	= $(SRC:%=examples/Roman/%) examples/Roman/README examples/Roman/Makefile

#*---------------------------------------------------------------------*/
#*    the goals.                                                       */
#*---------------------------------------------------------------------*/
$(DEST): $(OBJ) 
	$(BIGLOO) $(LNFLAGS) $(OBJ) -o $(DEST)

test: $(DEST)
	echo "(+ iii i)" | ./$(DEST)

pop:
	@ echo $(POPULATION)

#*---------------------------------------------------------------------*/
#*    Cleaning                                                         */
#*---------------------------------------------------------------------*/
.PHONY: clean

clean:
	@ find . \( -name '*[~%]' \
                       -o -name '.??*[~%]' \
                       -o -name '#*#' \
                       -o -name '?*#' \
                       -o -name \*core \) \
                     -type f -exec $(RM) {} \;   
	@- $(RM) -f $(OBJ)
	@- $(RM) -f $(DEST) 

#*---------------------------------------------------------------------*/
#*    Suffixes                                                         */
#*---------------------------------------------------------------------*/
.SUFFIXES:
.SUFFIXES: .scm .c .o

#*---------------------------------------------------------------------*/
#*    .c.o                                                             */
#*---------------------------------------------------------------------*/
.c.o:
	@ echo $*.c:
	@ $(CC) -c $(CFLAGS) $*.c -o $*.o

#*---------------------------------------------------------------------*/
#*    .scm.o                                                           */
#*---------------------------------------------------------------------*/
.scm.o:
	$(BIGLOO) -c $(BFLAGS) $*.scm -o $*.o

