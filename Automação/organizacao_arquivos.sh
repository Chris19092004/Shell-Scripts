#!/bin/bash

set -euo pipefail

# Cria a variável $DIRETORIO, que se não for definida, receberá como valor o meu diretório de Downloads na minha home.
# O diretório a ser organizado pode ser alterado na hora da execução com o comando abaixo:
# ./organizacao_arquivos.sh [diretório desejado]
DIRETORIO="${1:-/home/chris/Downloads}"

# Muda para o diretório definido em $DIRETORIO.
cd "$DIRETORIO"

# Declara os diretórios para onde os arquivos serão movidos em um array.
declare -A pastas=(
	[imagens]="$HOME/Pictures/Imagens"
	[pngs]="$HOME/Pictures/PNGs"
	[gifs]="$HOME/Pictures/GIFs"

	[videos]="$HOME/Videos/Vídeos"
	[audios]="$HOME/Music/Áudios"

	[livros]="$HOME/Documents/Livros"

	[scripts]="$HOME/Projects/Scripts"

	[python]="$HOME/Projects/Coding/Python"
	[c]="$HOME/Projects/Coding/C"
	[cpp]="$HOME/Projects/Coding/C++"
	[csharp]="$HOME/Projects/Coding/C#"
	[java]="$HOME/Projects/Coding/Java"
)

# Efetivamente cria os diretórios, usando o laço for que percorre cada elemento do array.
for destino in "${pastas[@]}"; do
	mkdir -p "${destino/#\~/$DIRETORIO}"
done

# Muda temporáriamente o comportamento do asterisco (*), para evitar conflitos em casos de diretórios vazios, por exemplo.
shopt -s nullglob

# Laço for que percorre TODOS os arquivos dentro do diretório definido em $DIRETORIO;
# Ele verifica se o arquivo atual é de fato um arquivo (e não um diretório, por exemplo "~/Arquivos.txt/") antes de continuar.
for arquivo in "$DIRETORIO"/*; do
	[[ -f "$arquivo" ]] || continue

	# Atribui cada extensão de arquivo a um destino.
	# Caso exista uma extensão não listada, aparece uma mensagem na tela dizendo que o arquivo em questão foi ignorado pelo script.
	# Duas vírgulas são usadas em 'case "${arquivo,,}"' para converter todo o nome do arquivo para lower case, caso exista um arquivo chamado "ARQUIVO.PDF", por exemplo.
	case "${arquivo,,}" in
		*.jpg|*.jpeg|*.webp) destino="${pastas[imagens]}" ;;
		*.png)               destino="${pastas[pngs]}" ;;
		*.gif)               destino="${pastas[gifs]}" ;;
		*.mp4|*.mkv)         destino="${pastas[videos]}" ;;
		*.mp3)               destino="${pastas[audios]}" ;;
		*.pdf)               destino="${pastas[livros]}" ;;
		*.sh)                destino="${pastas[scripts]}" ;;
		*.py)                destino="${pastas[python]}" ;;
		*.c)                 destino="${pastas[c]}" ;;
		*.cpp)               destino="${pastas[cpp]}" ;;
		*.cs)                destino="${pastas[csharp]}" ;;
		*.java)              destino="${pastas[java]}" ;;
		*)
			printf 'Extensão não listada; ignorando:  %s\n' "{$arquivo##*/}"
			continue
			;;
	esac

	# Move cada arquivo para seu destino atribuído.
	mv -- "$arquivo" "$destino/"
done

# Ao mover todos os arquivos, exibe uma mensagem para o usuário.
printf "Arquivos Movidos com Sucesso!"
