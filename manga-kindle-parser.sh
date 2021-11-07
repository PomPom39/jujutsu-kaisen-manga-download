#!/bin/bash
# Jujutsu Kaisen Manga Downloader (PDF Only)
# Author: Mahesh D
# Date: 07/11/2021
 
 
 
SCRIPT_VERSION="1.0"
MANGA_SITE_URL_TEMPLATE="https://jujustukaisen.com/manga/jujustu-kaisen-chapter-[]/?`date +'%Y-%m-%d'`"

# Check for depencinies
# wget
# curl
# img2pdf



# 

function usage() {

echo "Usage: `basename $0` [ --chapter X ] [ --chapter-from X --chapter-to Y ] [ --version ] [ --clean-all ]"
echo " " 
echo "./`basename $0` --chapter 109 " 
echo "./`basename $0` --chapter-from 0 --chapter-to 100" 
echo "./`basename $0` --version " 
echo " "
echo "More Details:"
echo "--chapter-from				Download From"
echo "--chapter-to				Download To"
echo "--chapter				Sepcific Chapter"
echo "--clean-all				Clean temp filess"
echo "--version				Version"
}

function xmlgetnext() {
	local IFS='>'
	read -d '<' TAG VALUE
}

function loadnext() {

	cat $1 | while xmlgetnext; do echo $TAG; done; 


}
function check_url() {

	CHK=$(curl -LI $1 | awk '/location/{print $2}' | grep 'chapter')
	if [ -z "$CHK" ]; then
		echo "Chapter Does not Exist! ?? Please Check manually ( $1 )"
		exit
	fi

	
}

function cleanall() {
	rm -rf dist

}

function convert_chapter_pdf() {
	
	img2pdf -o publish/JK_Chapter_${1}.pdf dist/Chapter_${1}/*
	
}


function download_chapter() {

	local URL=""
	local CH_NO=${1}
	local PG_NO=0
	URL=$(echo ${MANGA_SITE_URL_TEMPLATE/[]/$1})
	check_url $URL
	
	#Make a dist folder
	mkdir -p publish
	mkdir -p dist/Chapter_${CH_NO}
	 
	#Download the page
	 curl -s $URL > tmp.xml
	 #loadnext tmp.xml | grep "lazyloaded" | awk '{print $3 "  "$6$7$8$9}' | cut -c 5- > urls.txt
	loadnext tmp.xml | grep "lazyloaded" | awk 'match($0, "src=") { print substr($0, RSTART, 70)}' | cut -c 5- > urls.txt
	sed -i 's/"//g' urls.txt
	awk -v chno="$1" -v pgno="$PG_NO" '{print "wget --no-clobber --timeout=300 " $1 " -O dist/Chapter_" chno "/" ++pgno  }' urls.txt | bash
	
}





# Parse Input from CMDLINE
function cmd_parser() {	
	if [[ "$#" -eq 0 ]]; then
		usage
		exit
	fi

	while [[ "$#" -gt 0 ]]; do
		KEY="$1"

		case $KEY in 
		--chapter-from)
			CHAPTER_FROM="$2"
			shift
			shift
			;;
		--chapter-to)
			CHAPTER_TO="$2"
			shift
			shift
			;;
		--chapter)
			CHAPTER="$2"
			shift
			shift
			;;
		-e|--email)
			EMAIL="$2"
			shift
			shift
			;;
		--clean-all)
			CLEAN_ALL="Y"
			shift
			;;
		--version)
			VERSION="Y"
			shift
			;;
		*)
			echo "Unknown option"
			POSITIONAL+=("$1")
			shift
			;;
		esac
	done

	if [ ! -z "$CHAPTER_FROM" ] && [ ! -z "$CHAPTER_TO" ]; then
		for i in $(seq $CHAPTER_FROM $CHAPTER_TO); do
			download_chapter $i
			convert_chapter_pdf $i
		done
		echo "[JKMD]Done. Files are in publish folder! "
		exit
	fi
	
	if [ ! -z "$CHAPTER" ]; then
		download_chapter $CHAPTER
		convert_chapter_pdf $CHAPTER
		echo "[JKMD]Done. Files are in publish folder! "
		exit
	fi

	if [ ! -z "$CLEAN_ALL" ]; then 
		cleanall
		echo "[JKMD]Done. Files Cleaned Succesfully! "
		exit
	fi
	
	if [ ! -z "$VERSION" ]; then 
		echo "Version: $SCRIPT_VERSION"
		echo "Manga Website: $MANGA_SITE_URL_TEMPLATE"
	fi
}

cmd_parser $@
