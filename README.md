# axelera-doc

Axelera AI Accelerator Firefly RK3588J Yocto Guide.

# Prerequisites

```
sudo apt update
pip install sphinx
pip install myst_parser
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
