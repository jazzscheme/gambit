/^[ 	]*VPATH[ 	]*=[^:]*$/d

s%@CFLAGS@%%g
s%@CPPFLAGS@%%g
s%@CXXFLAGS@%%g
s%@DEFS@% -DPACKAGE=\\"gambc\\" -DVERSION=\\"40\\" %g
s%@LDFLAGS@%%g
s%@LIBS@%%g
s%@exec_prefix@%${prefix}%g
s%@prefix@%/usr/local%g
s%@program_transform_name@%s,x,x,%g
s%@bindir@%${exec_prefix}/bin%g
s%@sbindir@%${exec_prefix}/sbin%g
s%@libexecdir@%${exec_prefix}/libexec%g
s%@datadir@%${prefix}/share%g
s%@sysconfdir@%${prefix}/etc%g
s%@sharedstatedir@%${prefix}/com%g
s%@localstatedir@%${prefix}/var%g
s%@libdir@%${exec_prefix}/lib%g
s%@includedir@%${prefix}/include%g
s%@oldincludedir@%/usr/include%g
s%@infodir@%${prefix}/info%g
s%@mandir@%${prefix}/man%g
s%@PACKAGE@%gambc%g
s%@VERSION@%40%g
s%@HAVEGCC@%yes%g
s%@srcdirpfx@%%g
s%@o@%obj%g
s%@CC_O@%cl -nologo -Oityb1 -G5s -MD $(CFLAGS) -c $(CC_O_ARGS) -D___SINGLE_HOST%g
s%@CC_O_SH@%cl -nologo -Oityb1 -G5s -MD $(CFLAGS) -c $(CC_O_SH_ARGS) -D___SINGLE_HOST%g
s%@LINK@%cl -nologo $(LFLAGS) \\$$OBJECTS ../lib/$(GAMBCLIB) $(CLIBS) -o \\$$EXECUTABLE%g
s%@LINK_SH@%cl -nologo $(LFLAGS) \\$$OBJECTS ../lib/$(GAMBCLIB_SH) -o \\$$EXECUTABLE%g
s%@LINK_SH_INSTALL@%cl -nologo $(LFLAGS) \\$$OBJECTS ../lib/$(GAMBCLIB_SH) -o \\$$EXECUTABLE%g
s%@CLIBS@%%g
s%@GAMBCLIB@%libgambc.lib%g
s%@GAMBCLIB_SH@%gambc.lib%g
s%@MAKE_GAMBCLIB@%lib -out:$(GAMBCLIB) \\$$OBJECTS%g
s%@MAKE_GAMBCLIB_SH@%link -nologo -dll $(LFLAGS) -out:gambc.dll \\$$OBJECTS $(CLIBS)%g
s%@SETDLPATH@%OLDPATH="$$PATH" PATH="$$OLDPATH;..\\\\\\\\lib"%g
s%@INSTALL@%../inst-sh -c%g
s%@INSTALL_DATA@%../inst-sh -c -m 644%g
s%@INSTALL_PROGRAM@%../inst-sh -c -m 755%g
s%@SET_MAKE@%%g

s%@srcdir@%.%g
s%# makefile %\
SHELLMETAS = ;*?"<>|()&][$$\#`'\
SHELLFLAGS = -c\
GROUPSUFFIX = .ksh\
GROUPFLAGS = \
MAKE = $(MAKECMD) $(MFLAGS)\
# makefile %g
s%-I$(srcdirpfx)../lib%-I$(srcdirpfx)..\\\\\\\\lib%g
