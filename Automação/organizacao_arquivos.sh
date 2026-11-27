#!/bin/bash

set -euo pipefail

cd ~/Downloads

mkdir -p ~/Pictures/Imagens
mkdir -p ~/Pictures/PNGs
mkdir -p ~/Pictures/GIFs

mkdir -p ~/Videos/Vídeos
mkdir -p ~/Music/Áudios

mkdir -p ~/Documents/Livros

mkdir -p ~/Projects/'Shell Scripts'
mkdir -p ~/Projects/Coding/Python
mkdir -p ~/Projects/Coding/C
mkdir -p ~/Projects/Coding/C++
mkdir -p ~/Projects/Coding/C#
mkdir -p ~/Projects/Coding/Java

for i in ~/Downloads/*; do
	if [[ -f "$i" && "$i" == *.jpg || "$i" == *.jpeg || "$i" == *.webp ]]; then
		mv "$i" ~/Pictures/Imagens

	elif [[ -f "$i" && "$i" == *.png ]]; then
		mv "$i" ~/Pictures/PNGs

	elif [[ -f "$i" && "$i" == *.gif ]]; then
		mv "$i" ~/Pictures/GIFs


	elif [[ -f "$i" && "$i" == *.mp4 || "$i" == *.mkv ]]; then
		mv "$i" ~/Videos/Vídeos


	elif [[ -f "$i" && "$i" == *.mp3 ]]; then
		mv "$i" ~/Music/Áudios

	elif [[ -f "$i" && "$i" == *.pdf ]]; then
		mv "$i" ~/Documents/Livros

	
	elif [[ -f "$i" && "$i" == *.sh ]]; then
		mv "$i" ~/Projects/'Shell Scripts'

	elif [[ -f "$i" && "$i" == *.py ]]; then
		mv "$i" ~/Projects/Coding/Python

	elif [[ -f "$i" && "$i" == *.c ]]; then
		mv "$i" ~/Projects/Coding/C

	elif [[ -f "$i" && "$i" == *.cpp ]]; then
		mv "$i" ~/Projects/Coding/C++

	elif [[ -f "$i" && "$i" == *.cs ]]; then
		mv "$i" ~/Projects/Coding/'C#'

	elif [[ "$i" && "$i" == *.java ]]; then
	      mv "$i" ~/Projects/Coding/Java	

	fi
done

printf "\nArquivos movidos com sucesso!"
