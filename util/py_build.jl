## Builds the Python dependecies for the project.
## See https://gist.github.com/Luthaf/368a23981c8ec095c3eb
## See https://stackoverflow.com/questions/12332975/installing-python-module-within-code.

using PyCall

const PACKAGES = ["cryptography"]

println("Installing Python packages $PACKAGES ...")

pyimport("pip")

run(`$(PyCall.python) -m pip install $(PACKAGES)`)#

println("Finished installing packages $PACKAGES")