#!/bin/bash

# MASSE MASSE Paul-Basthylle
# 22U2001


############ Connection user ##################

connect_user() {
    local username=$1
    local start_connect="10:00:00"
    local disconnect="22:00:00"
    local heure_actuelle=$(date +"%H:%M:%S")

    # Vérifie si l'utilisateur appartient au groupe "restreint"
    if id -nG "$username" | grep -qw "restreint"; then
        if [[ "$heure_actuelle" > "$start_connect" && "$heure_actuelle" < "$disconnect" ]]; then
            echo "Bienvenue, $username ! Vous êtes autorisé à vous connecter."
            
            # Force le changement de mot de passe si c'est la première connexion
            if sudo chage -l "$username" | grep -q "Password must be changed"; then
                echo "Il semble que vous deviez changer votre mot de passe pour la première connexion."
                sudo passwd -e "$username"  # Force le changement du mot de passe à la première connexion
            fi

            # Vérifie si le mot de passe a été forcé pour être changé
            if sudo chage -l "$username" | grep -q "Password expired"; then
                echo "Veuillez changer votre mot de passe maintenant."
                exit 0
            fi

            # Se connecter en tant que l'utilisateur
            su - "$username"
        else
            echo "Désolé, $username. Vous ne pouvez pas vous connecter à cette heure-ci."
            echo "Il est déjà $heure_actuelle ! Sorry !"
            exit 1
        fi
    else
        echo "Accès refusé : $username ne fait pas partie du groupe 'restreint'."
        exit 1
    fi
}


############ Creation User ##################

creation_user() {
    local username=$1
    local password_default="inf361"
    local comment="Je suis"
    local disk_quota="1G"
    local expiration_date=$(date -d "+10 days" +%Y-%m-%d)

    # Crée l'utilisateur avec un commentaire
    sudo useradd -m -s /bin/bash -c "$comment $username" "$username"
    echo "$comment $username."

    # Définit le mot de passe par défaut
    echo "$username:$password_default" | sudo chpasswd
    echo "Mot de passe généré pour $username : $password_default"

    # Ajoute l'utilisateur au groupe "restreint"
    sudo usermod -aG restreint "$username"
    echo "L'utilisateur $username a été ajouté au groupe 'restreint'."

    # Ajout de l'utilisateur au groupe sudo
    sudocommand="sudo usermod -aG sudo \"$username\""
    eval "$sudocommand"
    if [ $? -eq 0 ]; then
        echo "Droits sudo accordés à '$username'."
    else
        echo "Erreur lors de l'ajout de l'utilisateur '$username' au groupe sudo."
        return 1
    fi

   expireCommand="sudo passwd -e \"$username\""
eval "$expireCommand"
if [ $? -eq 0 ]; then
    echo "L'utilisateur '$username' doit changer son mot de passe à la première connexion."
else
    echo "Erreur lors de la définition de l'expiration du mot de passe pour '$username'."
    return 1
fi


#expiration compte

    sudo chage -E "$expiration_date" "$username"
    echo "Le compte $username expirera le $expiration_date."
    
#Appel de la fonction de creation disque

    creation_disk "$username" "$disk_quota"
}



############ Gestion des disques ##################

#Fonction permettant de creer le disque de l'user

creation_disk() {
    local username=$1
    local disk_quota=$2

    local volume_name="lv_${username}"
    local vg_name="users_vg" 
    local mount_point="/home/$username"

    # Vérifie si le groupe de volumes existe
    
    if ! sudo vgdisplay "$vg_name" &>/dev/null; then
        echo "Le groupe de volumes $vg_name n'existe pas. Veuillez le créer avant d'exécuter ce script."
        return 1
    fi

    # Crée un volume logique de la taille spécifiée
    
    sudo lvcreate -L "$disk_quota" -n "$volume_name" "$vg_name"
    if [ $? -ne 0 ]; then
        echo "Échec de la création du volume logique $volume_name."
        return 1
    fi
    echo "Volume logique $volume_name créé avec succès."

    # Formate le volume en ext4
    
    sudo mkfs.ext4 "/dev/$vg_name/$volume_name"
    echo "Volume $volume_name formaté en ext4."

    # Monte le volume sur le répertoire personnel de l'utilisateur
    
    sudo mount "/dev/$vg_name/$volume_name" "$mount_point"
    echo "Volume monté sur $mount_point."

    # Ajoute une entrée dans /etc/fstab pour le montage persistant
    
    echo "/dev/$vg_name/$volume_name $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab

    # Définit les permissions pour l'utilisateur
    
    sudo chown -R "$username:$username" "$mount_point"
    echo "Permissions définies pour l'utilisateur $username sur $mount_point."

    echo "L'utilisateur $username a été créé avec un espace disque limité à $disk_quota."
}



#Rien que pour un test global  test immediat si ca rate

creation_userok() {
    local username=$1
    local password_default="inf361"
    local comment="Je suis "
    local disk_quota="1G"
    local expiration_date=$(date -d "+10 days" +%Y-%m-%d)

	# Crée l'utilisateur avec un commentaire
	   
	sudo useradd -m -s /bin/bash -c "$comment" "$username"
	echo "$comment $username"

	# Définit le mot de passe par défaut
	
	echo "$username:$password_default" | sudo chpasswd
	echo "Mot de passe généré pour $username : $password_default"

	# Ajoute l'utilisateur au groupe "restreint"
	
	sudo usermod -aG restreint "$username"
	echo "L'utilisateur $username a été ajouté au groupe 'restreint'."


	# Applique la date d'expiration à l'utilisateur
	
	sudo chage -E "$expiration_date" "$username"
	echo "Le compte $username expirera le $expiration_date."
	


    # Crée un volume logique LVM pour l'utilisateur
    
    local volume_name="lv_${username}"
    local vg_name="users_vg" # Volume group à définir
    local mount_point="/home/$username"

    # Vérifie si le groupe de volumes existe
    if ! sudo vgdisplay "$vg_name" &>/dev/null; then
        echo "Le groupe de volumes $vg_name n'existe pas. Veuillez le créer avant d'exécuter ce script."
        return 1
    fi

    # Crée un volume logique de la taille spécifiée
    sudo lvcreate -L "$disk_quota" -n "$volume_name" "$vg_name"
    if [ $? -ne 0 ]; then
        echo "Échec de la création du volume logique $volume_name."
        return 1
    fi
    echo "Volume logique $volume_name créé avec succès."

    # Formate le volume en ext4
    
    sudo mkfs.ext4 "/dev/$vg_name/$volume_name"
    echo "Volume $volume_name formaté en ext4."

    # Monte le volume sur le répertoire personnel de l'utilisateur
    
    sudo mount "/dev/$vg_name/$volume_name" "$mount_point"
    echo "Volume monté sur $mount_point."

    # Ajoute une entrée dans /etc/fstab pour le montage persistant
    
    echo "/dev/$vg_name/$volume_name $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab

    # Définit les permissions pour l'utilisateur
    
    sudo chown -R "$username:$username" "$mount_point"
    echo "Permissions définies pour l'utilisateur $username sur $mount_point."

    echo "L'utilisateur $username a été créé avec un espace disque limité à $disk_quota."
}



############ Affichage des users ##################

Affichage_user_restreint() {
    echo "Liste des utilisateurs du groupe 'restreint' :"
    getent group restreint | awk -F: '{print $4}' | tr ',' '\n'
}

Affichage_all_user() {
    echo "Liste de tous les utilisateurs :"
    getent passwd | awk -F: '{print $1}'
}


############ Supression User ##################

supprimer_user() {	#supprime l'user ainsi que le repertoire
    local USERNAME=$1
    local home_dir="/home/$USERNAME"

    # Vérifie si l'utilisateur existe
    if ! id "$USERNAME" &>/dev/null; then
        echo "L'utilisateur $USERNAME n'existe pas."
        return 1
    fi

    # Supprime l'utilisateur et son répertoire personnel
    
    sudo deluser --remove-home "$USERNAME"
    if [ $? -eq 0 ]; then
        echo "Utilisateur $USERNAME et son répertoire personnel supprimés."
    else
        echo "Erreur lors de la suppression de l'utilisateur $USERNAME."
        return 1
    fi   
}


############ Menu Principal ##################

menuprincipal() {
    while true; do
        echo "############=== MENU PRINCIPAL ===##################"
        echo "1. Connecter un utilisateur"
        echo "2. Créer un utilisateur et l'ajouter au groupe 'restreint'"
        echo "3. Afficher les utilisateurs du groupe 'restreint'"
        echo "4. Afficher tous les utilisateurs"
        echo "5. Supprimer un utilisateur"
        echo "0. Quitter"
        read -p "Choisissez une option : " choix

        case $choix in
            1)
                read -p "Entrez le nom de l'utilisateur : " username
                connect_user "$username"
                ;;
            2)
                read -p "Entrez le nom de l'utilisateur à créer : " username
                creation_user "$username"
                ;;
            3)
                Affichage_user_restreint
                ;;
            4)
                Affichage_all_user
                ;;
            5)
                read -p "Entrez le nom de l'utilisateur à supprimer : " username
                supprimer_user "$username"
                ;;
            0)
                echo "Au revoir !"
                exit 0
                ;;
            *)
                echo "Option invalide. Veuillez choisir une option valide."
                ;;
        esac
        echo ""
    done
}
# Lancement du menu principal
menuprincipal

