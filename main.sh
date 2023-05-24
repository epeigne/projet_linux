#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------PARAMETRES-----------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

echo "--------------------------------------------------"
echo "--ATTENTION MODIFIER MAIL DESTINATAIRE LIGNE 130--"
echo "--------------------------------------------------"

# Demander à l'utilisateur de saisir les paramètres mail
echo "Veuillez entrer une adresse smtp :"
read smtpaddress
echo "Veuillez entrer un port smtp :"
read smtpport
echo "Veuillez entrer un login (mail pour le serveur smtp) :"
read userlogin
echo "Veuillez entrer un mot de passe (attention aux caractères spéciaux) :"
read userpass
smtpserv=$smtpaddress":"$smtpport
#echo $smtpserv

# Définir le chemin d'accès du fichier CSV
csv_file="accounts.csv"


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------LECTURE CSV----------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' 'NR>1 { print $1}' "$csv_file">name.txt
awk -F ';' 'NR>1 { print $2}' "$csv_file">surname.txt
awk -F ';' 'NR>1 { print $3}' "$csv_file">mail.txt
awk -F ';' 'NR>1 { print $4}' "$csv_file">password.txt

#avoir le nombre de lignes du csv
nb_lignes=$(wc -l < $csv_file)

#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------ECLIPSE--------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

#telechargement eclipse et deplacement dans /opt
wget --directory-prefix=/opt/ https://ftp.fau.de/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz && tar xzvf /opt/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz -C "/opt/" eclipse && chown -R root:root /opt/eclipse/ 


#ajout droit execution
chmod a+x /opt/eclipse/eclipse

#suppression du tar
rm -f /opt/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------CREATION USER--------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

for((i=1;i<=$nb_lignes;i++));
do

    #creation variables data user

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
    useradd -s /bin/bash -m $username
    echo $username:$passwd | chpasswd

    #expiration du mot de passe
    chage --lastday 0 $username

    #creation dossier sauvegarde 
    mkdir /home/$username/a_sauver

    #creation dossier shared si il n'existe pas
    if [ ! -d /home/shared ]
    then
        mkdir /home/shared
        chown root:root /home/shared
        chmod 775 /home/shared
    fi

    #creation dossier user dans shared
    mkdir /home/shared/$username
    chown $username:$username /home/shared/$username
    chmod 755 /home/shared/$username

    #creation lien symbolique dans home user vers ecplise
    ln -s /opt/eclipse/eclipse /home/$username/eclipse

    #-----------------------------------------------------------------------------------------------------------------
    #--------------------------------------------------ENVOI DE MAIL--------------------------------------------------
    #-----------------------------------------------------------------------------------------------------------------

    #remplacement de @ par %40 pour l'envoi du mail
    userlogin_smtp=$(echo $userlogin | sed 's/@/%40/g')

    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "echo -e \"Bonjour $name $surname,\n\nVous trouverez ci-joint vos identifiants:\nUsername: $username\nPassword: $passwd\n\nAttention: vous devrez changer votre mot de passe lors de votre première connexion!\" | mail --subject \"Création compte Linux\" --exec \"set sendmail=smtp://$userlogin_smtp:$userpass;auth=LOGIN@$smtpserv\" --append "From:$userlogin" smtplinuxproject@gmail.com"


    #-----------------------------------------------------------------------------------------------------------------
    #--------------------------------------------------SAUVEGARDE-----------------------------------------------------
    #-----------------------------------------------------------------------------------------------------------------

    #creation dossier saves sur serveur de sauvegarde
    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "mkdir saves"
    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "chmod 666 saves"

    #creation crontab pour sauvegarde automatique
    crontab -l > /tmp/crontab.tmp
    echo "*/2 * * * * tar -czf /home/$username/save_$username.tgz -C \"/home/$username/\" a_sauver/ && chmod a+x /home/$username/save_$username.tgz && scp -i /root/.ssh/id_rsa /home/$username/save_$username.tgz epeign25@10.30.48.100:/home/saves && rm -f /home/$username/save_$username.tgz" >> /tmp/crontab.tmp
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp

    #recuperation sauvegarde
    echo "scp -i /root/.ssh/id_rsa epeign25@10.30.48.100:/home/saves/save_$username.tgz /home/$username &&  tar -xzf /home/$username/save_$username.tgz -C "/home/$username" && rm -f /home/$username/save_$username.tgz" > /home/$username/retablir_sauvegarde.sh
    chmod a+x /home/$username/retablir_sauvegarde.sh

done