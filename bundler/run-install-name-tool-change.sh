#!/bin/sh

if [ $# -lt 3 ]; then
    echo "Usage: $0 library old_prefix new_prefix action"
    exit 1
fi

LIBRARY=$1
WRONG_PREFIX=$2
RIGHT_PREFIX="@executable_path/../../$3"
ACTION=$4

chmod u+w $LIBRARY

if [ "x$ACTION" == "xchange" ]; then
    libs="`otool -L $LIBRARY 2>/dev/null | fgrep compatibility | cut -d\( -f1 | grep $WRONG_PREFIX | sort | uniq`"
    for lib in $libs; do
	if ! echo $lib | grep --silent "@executable_path" ; then
	    fixed=`echo $lib | sed -e s,\$WRONG_PREFIX,\$RIGHT_PREFIX,`
	    # Check if we run in a homebrew environment and replace all "Cellar" library
	    # locations with the location in opt/lib. Library locations with "Cellar" are used as indication
	    # that we run in homebrew.
	    # Example: /usr/local/homebrew/Cellar/pango/1.50.3/lib/libpango-1.0.0.dylib translates via
	    # libname = "pango" and libfullname = "lib/libpango-1.0.0.dylib" to
	    # @executable_path/../Resources/opt/pango/lib/libpango-1.0.0.dylib
	    if echo $lib | grep --silent "Cellar" ; then
		libname=`echo $lib | sed -n 's/.*Cellar\/\([^\/]*\)\/.*/\1/p'`
		libfullname=`echo $lib | sed -n 's/.*\/\(lib\/.*\)/\1/p'`
		fixed="$RIGHT_PREFIX/opt/$libname/$libfullname"
	    fi
	    install_name_tool -change $lib $fixed $LIBRARY
	fi
    done;
elif [ "x$ACTION" == "xid" ]; then
    lib="`otool -D $LIBRARY 2>/dev/null | grep ^$WRONG_PREFIX | sed s,\${WRONG_PREFIX},,`"
    install_name_tool -id "$RIGHT_PREFIX/$lib" $LIBRARY;
fi
    
