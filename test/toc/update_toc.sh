sed -i.bak -e 's/\\chapter\*{\([^}]*\)}/&\n\\addcontentsline{toc}{chapter}{\1}/' toc.tex
