puttygen /mnt/c/Users/A200128991/.ssh/id_rsa.ppk -O private-openssh -o ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa

