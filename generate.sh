# !/bin/bash
cp next_theme_config.yml  themes/hexo-theme-next/_config.yml
ln -sfv `pwd`/themes_plugins/* themes/hexo-theme-next/source/lib/
hexo clean
hexo g
