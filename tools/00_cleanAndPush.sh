echo "***************************************************************************************************************************************************"
echo " 🚀  Clean for GIT Push"
echo "***************************************************************************************************************************************************"


export gitCommitMessage=$(date +%Y%m%d-%H%M)

echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🗄️  Make local copy ../ARCHIVE/aiops-ansible-$gitCommitMessage"
echo "--------------------------------------------------------------------------------------------------------------------------------"

mkdir -p ../ARCHIVE/awx-training-data-$gitCommitMessage

cp -r * ../ARCHIVE/awx-training-data-$gitCommitMessage
cp .gitignore ../ARCHIVE/awx-training-data-$gitCommitMessage
 

echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Find File Copies"
echo "--------------------------------------------------------------------------------------------------------------------------------"
find . -name '*copy*' -type f | grep -v DO_NOT_DELIVER
find . -name '*test*' -type f | grep -v DO_NOT_DELIVER
find . -name '*tmp*' -type f | grep -v DO_NOT_DELIVER


echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Deleting large and sensitive files"
echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "      ❎  Deleting DS_Store"
find . -name '.DS_Store' -type f -delete



rm -f ./iaf-system-backup.yaml

export actBranch=$(git branch | tr -d '* ')
echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Update Branch to $actBranch"
echo "--------------------------------------------------------------------------------------------------------------------------------"



read -p " ❗❓ do you want to check-in the GitHub branch $actBranch with message $gitCommitMessage? [y,N] " DO_COMM
if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
    echo "   ✅ Ok, committing..."
    git add . && git commit -m $gitCommitMessage 
else
    echo "    ⚠️  Skipping"
fi

read -p " ❗❓ Does this look OK? [y,N] " DO_COMM
if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
    echo "   ✅ Ok, checking in..."
    git push
else
    echo "    ⚠️  Skipping"
fi



