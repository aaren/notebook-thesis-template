latex:
	ipython nbconvert --config config.py example.ipynb

notebook:
	notedown example.md > example.ipynb

all: notebook latex
