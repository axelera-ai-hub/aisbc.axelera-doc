# axelera-doc

Axelera AI Accelerator Firefly RK3588J Yocto Guide.

# Prerequisites

```
sudo apt update
sudo apt install python3-sphinx python3-myst-parser python3-sphinx-copybutton latexmk texlive-latex-extra
```

# Build html

```
make html
firefox _build/html/index.html 
```

# Build pdf

```
sudo apt update
sudo apt-get install texlive texlive-latex-extra texlive-fonts-recommended latexmk
make latexpdf
evince _build/latex/axelera-bsp.pdf
```
