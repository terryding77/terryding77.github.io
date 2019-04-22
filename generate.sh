# !/bin/bash
ln -sfv `pwd`/themes_plugins/* themes/hexo-theme-next/source/lib/
hexo clean
hexo g
