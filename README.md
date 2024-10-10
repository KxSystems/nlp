# ⚠️ **This repository is outdated!** ⚠️

---

Since 9th October 2024 (the 4.0.0 release of the ML Toolkit), this project has been merged into the ml toolkit mono-repo. For the latest updates and active development, please visit [https://github.com/KxSystems/ml](https://github.com/KxSystems/ml). 

This repository is preserved only to maintain old links and project history but will no longer be actively maintained.

---

# Natural Language Processing

## Introduction

Natural language processing (NLP) can be used to answer a variety of questions about unstructured text, as well as facilitating open-ended exploration. It can be applied to datasets such as emails, online articles and comments, tweets and novels. Although the source is text, transformations are applied to convert this data to vectors, dictionaries and symbols which can be handled very effectively by q. Many operations such as searching, clustering, and keyword extraction can all be done using very simple data structures, such as feature vectors.

## Features

The NLP allows users to parse dataset using the spacy model from python in which it runs tokenisation, Sentence Detection, Part of speech tagging and Lemmatization. In addition to parsing, users can cluster text documents together using different clustering algorithms like MCL, K-means and radix. You can also run sentiment analysis which indicates whether a word has a positive or negative sentiment.

## Requirements
- kdb+>=? v3.5 64-bit
- Anaconda Python 3.x
- [embedPy](https://github.com/KxSystems/embedPy)

#### Dependencies
The following python packages are required:
  1. numpy
  2. beautifulsoup4
  3. spacy 

* Tests were run using spacy version 2.2.1

To install these packages with

pip
```bash
pip install -r requirements.txt
```
or with conda
```bash
conda install -c conda-forge --file requirements.txt
```

* Download the English model using ```python -m spacy download en```

Other languages that spacy supports can be found at https://spacy.io/usage/models#languages

To use the languages in the alpha stage of developement in spacy the following steps can be taken:

To Download the Chinese model the jieba must be installed

pip
```bash
pip install jieba
```

To download the Japanese model mecab must be installed

pip
```bash
pip install mecab-python3
```

* spacy_hunspell is not a requirement to run these scripts, but can be installed using the following methods

Linux
```bash
sudo apt-get install libhunspell-dev hunspell
pip install spacy_hunspell
```

mac
```bash
wget https://iweb.dl.sourceforge.net/project/wordlist/speller/2019.10.06/hunspell-en_US-2019.10.06.zip;
unzip hunspell-en_US-2019.10.06; sudo mv en_US.dic en_US.aff /Library/Spelling/; 
brew install hunspell;
export C_INCLUDE_PATH=/usr/local/include/hunspell;
sudo ln -sf /usr/local/lib/libhunspell-1.7.a /usr/local/lib/libhunspell.a;
sudo ln -sf /usr/local/Cellar/hunspell/1.7.0_2/lib/libhunspell-1.7.dylib /usr/local/Cellar/hunspell/1.7.0_2/lib/libhunspell.dylib;
CFLAGS=$(pkg-config --cflags hunspell) LDFLAGS=$(pkg-config --libs hunspell) pip install hunspell==0.5.0
```

At the moment spacy_hunspell does not support installation for windows. More information can be found at https://github.com/tokestermw/spacy_hunspell

## Installation
Run tests with

```bash
q test.q
```

Place the library file in `$QHOME` and load into a q instance using 

```q
q)\l nlp/nlp.q
q).nlp.loadfile`:init.q
Loading init.q
Loading code/utils.q
Loading code/regex.q
Loading code/sent.q
Loading code/parser.q
Loading code/time.q
Loading code/date.q
Loading code/email.q
Loading code/cluster.q
Loading code/nlp_code.q
q).nlp.findTimes"I went to work at 9:00am and had a coffee at 10:20"
09:00:00.000 "9:00am" 18 24
10:20:00.000 "10:20"  45 50
```

### Docker

If you have [Docker installed](https://www.docker.com/community-edition) you can alternatively run:

    $ docker run -it --name mynlp kxsys/nlp
    kdb+ on demand - Personal Edition
    
    [snipped]
    
    I agree to the terms of the license agreement for kdb+ on demand Personal Edition (N/y): y
    
    If applicable please provide your company name (press enter for none): ACME Limited
    Please provide your name: Bob Smith
    Please provide your email (requires validation): bob@example.com
    KDB+ 3.5 2018.04.25 Copyright (C) 1993-2018 Kx Systems
    l64/ 4()core 7905MB kx 0123456789ab 172.17.0.2 EXPIRE 2018.12.04 bob@example.com KOD #0000000

    Loading code/utils.q
    Loading code/regex.q
    Loading code/sent.q
    Loading code/parser.q
    Loading code/time.q
    Loading code/date.q
    Loading code/email.q
    Loading code/cluster.q
    Loading code/nlp_code.q
    q).nlp.findTimes"I went to work at 9:00am and had a coffee at 10:20"
    09:00:00.000 "9:00am" 18 24
    10:20:00.000 "10:20"  45 50
    

**N.B.** [instructions regarding headless/presets are available](https://github.com/KxSystems/embedPy/docker/README.md#headlesspresets)

**N.B.** [build instructions for the image are available](docker/README.md)



## Documentation

Documentation is available on the [nlp](https://code.kx.com/v2/ml/nlp/) homepage.

 

## Status
  
The nlp library is still in development and is available here as a beta release.  
If you have any issues, questions or suggestions, please write to ai@kx.com.
