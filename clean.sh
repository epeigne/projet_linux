#!/bin/bash

csv_file="accounts.csv"

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' 'NR>1 { print $1}' "$csv_file">name.txt
awk -F ';' 'NR>1 { print $2}' "$csv_file">surname.txt
awk -F ';' 'NR>1 { print $3}' "$csv_file">mail.txt
awk -F ';' 'NR>1 { print $4}' "$csv_file">password.txt


#avoir le nombre de lignes du csv
nb_lignes=$(wc -l < $csv_file)

#creation variables data user 
for((i=1;i<=$nb_lignes;i++));
do
    name=$(awk -v line="$i" 'NR==line{print $1}' name.txt)
    surname=$(awk -v line="$i" 'NR==line{print $1}' surname.txt)
    mail=$(awk -v line="$i" 'NR==line{print $1}' mail.txt)
    passwd=$(awk -v line="$i" 'NR==line{print $1}' password.txt)

    #afficher premiere lettre du prenom et creer username en minuscule
    first_letter=${name:0:1}
    username=$(echo $first_letter$surname | tr '[:upper:]' '[:lower:]')

    #remove user
    sudo deluser --remove-home $username
done

#remove shared folder
sudo rm -r /home/shared

#remove txt files
rm name.txt
rm surname.txt
rm mail.txt
rm password.txt
