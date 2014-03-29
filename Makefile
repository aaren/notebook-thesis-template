latex:
	ipython nbconvert --config config.py example.ipynb

notebook:
	notedown example.md > example.ipynb

run-notebook:
	runipy example.ipynb example.ipynb

all: notebook run-notebook latex
