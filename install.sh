!/bin/bash
# install curl

sudo apt install curl

# install nvm (for markdown preview)

curl -o-  https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash

# install Vim-instant-markdown

sudo apt install xdg-utils
nvm -g install instant-markdown-d

# install tmux
xdg-uadds

sudo apt install tmux
cp tmux.conf.example ~/.tmux.conf

# install vim

sudo apt install vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
	    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
cp vimrc.example ~/.vimrc

# install zsh and p10k
sudo apt install zsh
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
cp zshrc.example ~/.zshrc
cp p10k.zsh.example .p10k.zsh


