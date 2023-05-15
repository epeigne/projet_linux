#!/bin/bash


# Définir le chemin d'accès du fichier CSV
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

#print de verif
#echo $name $surname $mail $passwd

#afficher premiere lettre du prenom et creer username en minuscule
first_letter=${name:0:1}
username=$(echo $first_letter$surname | tr '[:upper:]' '[:lower:]')

#creation user avec adduser et set passwd
sudo useradd -s /bin/bash -m $username
echo $username:$passwd | sudo chpasswd

#expiration du mot de passe
sudo chage --lastday 0 $username

#creation dossier sauvegarde 
sudo mkdir /home/$username/a_sauver

#creation dossier shared
if [ ! -d /home/shared ]
then
sudo mkdir /home/shared
sudo chown root:root /home/shared
sudo chmod 775 /home/shared
fi

#creation dossier user dans shared
sudo mkdir /home/shared/$username
sudo chown $username:$username /home/shared/$username
sudo chmod 755 /home/shared/$username

done