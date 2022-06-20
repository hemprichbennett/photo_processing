cd /Volumes/dhb_lacie_1/photography_main/1_all_unedited
echo "Do you want to make a new directory?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "Ok, what should the directory name be?"; 
        read desired_dirname;
        root_dir=$(ls -d $PWD/* | tail -1)
        new_dir="${root_dir}/${desired_dirname}"
        echo making $new_dir;
        mkdir $new_dir
        rsync -arvzp /Volumes/EOS_DIGITAL/DCIM/100EOS5D/* $new_dir
        break;;
        No ) chosen_dir=$(ls -d $PWD/*/* | tail -1);
        echo copying files to $chosen_dir;
        rsync -arvzp /Volumes/EOS_DIGITAL/DCIM/100EOS5D/* $chosen_dir;
        echo "done";
        exit;;
    esac
done
