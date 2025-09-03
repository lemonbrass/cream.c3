### THIS PROJECT IS BEING REPLACED BY [liebe](https://github.com/coppamocha/liebe)

## Introduction
cream.c3 is a tool for managing c3 projects, adding external dependencies and it does all that in a neat (and reproducible) way with a toml config much inspired by cargo.

## Installation
### Prerequisites
 C3 compiler (0.6.2+)
### Steps
#### Clone the repo
```sh
git clone https://github.com/lemonbrass/cream.c3 --depth=1 cream
cd cream
```
#### Build
if you are building cream the first time:
run 
```sh 
c3c build [debug/release]
```
the binary will be stored in build/(creamdeb/creamrel)

Or if you have a cream binary already installed.
Just run 
```sh
cream build [debug/release]
```
the binary will be stored in build/cream

Preferably, add the binary to path.

## Usage
#### Create a project
Run the command 
```cream create```
It will ask couple of questions about project and it will be generated in projname/ directory.

#### File structure
After creating project, you would be greeted with:

```plaintext
.
├── cream.toml
├── src/
│   └── main.c3
└── build/
```

main.c3 will contain a simple Hello World example to get you going.

the cream.toml is where all the magic happens. We will talk about it in later sections.

#### Building project
The cream.toml will have a `debug` target.
You can build the project by running:

```sh
cream build [target name]
```
The executable will be stored inside build/ directory.


## cream.toml
It contains all the configuration for cream including project specifications, targets, external deps (WIP) and internal deps (WIP).

### \[project]
All the project specifications lie here.

- name - project name
- version
- author - name of author
- description
- build-directory - by default, it is build/
- sources - a list of all the source directories.

### \[target.name]
Here, you specify the target specific things.

- flags - compiler flags
- before-build - command to run before building process is complete
- after-build - command to run after building process is complete

## References:
[https://c3-lang.org]

