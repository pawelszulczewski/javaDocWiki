#!/bin/bash

# psz, april 2014
# GNU/GPL v3+

# usage
#    -d <directory> -- directory with repository
#
# KNOWN BUGS
#    * program does not handle local paths
#
# TODO
#    * handle local paths,
#    * usage of create_doc function should be rewritten, now it is run
#      by every .java file in the directory, should be run one time
#      per directory
#
# exit codes
__ERR_PARAMETER=1             # wrong/missing parameter
__ERR_SOFTNINSL=2             # software not installed
__ERR_BADFOLDER=3             # the directory doesn't contain any SVN
			      # or git repository,
__REPO_NOT_UPDT=4             # respository is up to date

SFT_INSTALLED=1               # flag to check if all necessary
			      # software is installed

__TMP_FILE=/tmp/suzjavbot     # file with last revisions

# checks if software is installed
function check_if_installed {
    command -v $1 > /dev/null 2>&1 || {
	echo "Error -- $1 is not installed"
	if [ $SFT_INSTALLED -eq 1 ]; then
	    SFT_INSTALLED=0
	fi
    }
}

# checks if all necessary software is installed
function check_soft {
    check_if_installed 'git'
    check_if_installed 'svn'
    check_if_installed 'javadoc'
    check_if_installed 'pySuzadd.py'
    if [ $SFT_INSTALLED -eq 0 ]; then
	exit $__ERR_SOFTNINSL
    fi
}

# create documentation and create wiki page
function create_doc {

    # temporary stuff
    TMP_DIR=/tmp/suzuki_`date +%s`
    TMP_SUZ_DIR=$TMP_DIR/suziki/

    mkdir -p $TMP_SUZ_DIR

    # create documentation
    javadoc $1 -d "$TMP_DIR" -nonavbar -nohelp -noindex -notree -quiet

    FILENAMEORG=$(basename "$1")
    FILENAME="${FILENAMEORG%.*}".html
    find $TMP_DIR -name $FILENAME -print0 | xargs -I{} -0 cp {} $TMP_SUZ_DIR

    # this text is obsolete
    sed -i '/DOCTYPE HTML PUBLIC/d' $TMP_SUZ_DIR/$FILENAME	

    # create a page in wiki
    echo "generating... $FILENAMEORG"	
    pySuzadd.py $TMP_SUZ_DIR/$FILENAME $FILENAMEORG
    
    # clean up
    rm -rf $TMP_DIR
}

# main function
function main {
    CDIR=$PWD
    cd $1

    # -------------------------------------- GIT ---------------------------------------------
    git status > /dev/null 2>&1

    if [ `echo $?` -eq 0 ]; then
	
	cd $CDIR && cd $1

        # name of current branch
	GIT_BRANCH=`git branch --list | grep \* | cut -d"*" -f2 | tr -d "[:blank:]"`
        # name of repostitory | BUG? -- what if repository isn't remote?
	GIT_REPONAME=`git remote show`
        # checkout
	git pull -q $GIT_REPONAME $GIT_BRANCH
        # last commit's hash
	LASTREVGIT=`git rev-parse HEAD`

        # check last revision from $__TMP_FILE
	REPODIR=`echo $1 | sed -e 's/\//____/g'`
        if [ -f $__TMP_FILE ]; then
	    LASTREVGITFILE=`cat $__TMP_FILE | grep "$REPODIR" | cut -d"=" -f2`
	    if [ -z "$LASTREVGITFILE" ]; then
		LASTREVGITFILE=`git log --pretty=format:%H | tail -1`
	    fi
	else
	    # first commit ever
	    LASTREVGITFILE=`git log --pretty=format:%H | tail -1`
	fi

        # if repository was updated -- create doc and wiki page
	if [ "$LASTREVGIT" != "$LASTREVGITFILE" ]; then
	    if [ -f $__TMP_FILE ]; then
		sed -i /"$REPODIR"/d $__TMP_FILE
	    fi

	    for f in `git diff --name-only "$LASTREVGIT" "$LASTREVGITFILE" | grep "\.java"`
	    do
		create_doc $f
	    done

	    echo "$REPODIR=$LASTREVGIT" >> $__TMP_FILE
	else
	    echo "Repository is up to date."
	    exit $__REPO_NOT_UPDT	    
	fi

    else

	# -------------------------------------- SVN ---------------------------------------------
	cd $CDIR
	SVN_URL=`svn info $1 | grep URL | cut -d" " -f2 2>&1`

	if [ `echo $?` -eq 0 ] &&  [ "$SVN_URL" != "" ]; then
	    # checkout
	    cd `dirname $1` && svn checkout $SVN_URL --quiet

	    # last revision's number from repository
	    SVN_LST=`svn info $1 | grep Wersja | cut -d" " -f2`
	    REPODIR=`echo $1 | sed -e 's/\//____/g'`

	    # last revision's number from $__TMP_FILE
	    if [ -f $__TMP_FILE ]; then
		LASTREVFFILE=`cat $__TMP_FILE | grep "$REPODIR" | cut -d"=" -f2`
	    else
		LASTREVFFILE=0
	    fi

            # if repository was updated -- create doc and wiki page
	    if [ "$SVN_LST" != "$LASTREVFFILE" ]; then
		if [ -f $__TMP_FILE ]; then
		    sed -i /"$REPODIR"/d $__TMP_FILE
		fi

		cd $CDIR && cd $1

		for f in `svn diff --summarize -r "$LASTREVFFILE":HEAD | grep "\.java" | tr -d "[:blank:]" | cut -c2-` 
		do
		    create_doc $f
		done
    
		echo "$REPODIR=$SVN_LST" >> $__TMP_FILE
	    else
		echo "Repository is up to date."
		exit $__REPO_NOT_UPDT
     	    fi
	else
	    echo "Directory does not contain a svn or git repository."
	    cd $CDIR
	    return $__ERR_BADFOLDER
	fi	
    fi
    cd $CDIR
}

while getopts ":d:" opt; do
    case $opt in
	d)
	    check_soft
	    main $OPTARG
	    ;;
	\?)
	    echo "wrong parameter! $OPTARG" >&2
	    exit $__ERR_PARAMETER
	    ;;
        :)
	    echo "-d needs a value" >&2
	    exit $__ERR_PARAMETER
	    ;;
    esac
done

exit 0
