\d .nlp

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Pytho spell check function
p)def spell(doc,model):
  lst=[]
  for s in doc:
    if s._.hunspell_spell==False:
      sug=s._.hunspell_suggest
      if len(sug)>0:
        ([lst.append(n)for n in model((sug)[0])]) 
      else:lst.append(s)
    else:
        lst.append(s)
  return lst

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Python function for running spacy
p)def get_doc_info(parser,tokenAttrs,opts,text):
  doc=doc1=parser(text)
  if('spell' in opts):
    doc1=spell(doc,parser)
  res=[[getattr(w,a)for w in doc1]for a in tokenAttrs]
  if('sentChars' in opts): # indices of first+last char per sentence
    res.append([(s.start_char,s.end_char)for s in doc.sents])
  if('sentIndices' in opts): # index of first token per sentence
    res.append([s.start for s in doc.sents])
  res.append([w.is_punct or w.is_bracket or w.is_space for w in doc])
  return res

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Python functions to detect sentence borders
p)def x_sbd(doc):
  if len(doc):
    doc[0].is_sent_start=True
    for i,token in enumerate(doc[:-1]):
      doc[i+1].is_sent_start=token.text in ['。','？','！']
  return doc

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Retrieve python function for running spacy
parser.i.parseText:.p.get[`get_doc_info;<];

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Retrieve python function to decode bytes
parser.i.cleanUTF8:.p.import[`builtins;`:bytes.decode;<][;`errors pykw`ignore]$["x"]@;

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Dependent options for input to spacy module
parser.i.depOpts:(!). flip(
  (`keywords;   `tokens`isStop);
  (`sentChars;  `sentIndices);
  (`sentIndices;`sbd);
  (`uniPOS;     `tagger);
  (`pennPOS;    `tagger);
  (`lemmas;     `tagger);
  (`isStop;     `lemmas))

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Map from q-style attribute names to spacy
parser.i.q2spacy:(!). flip(
  (`likeEmail;  `like_email);
  (`likeNumber; `like_num);
  (`likeURL;    `like_url);
  (`isStop;     `is_stop);
  (`tokens;     `lower_);
  (`lemmas;     `lemma_);
  (`uniPOS;     `pos_);
  (`pennPOS;    `tag_);
  (`starts;     `idx))

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Model inputs for spacy 'alpha' models
parser.i.alphalang:(!). flip(
  (`ja;`Japanese);
  (`zh;`Chinese))

// @fileOverview Create a new parser
// @param modelName {sym} The spaCy model to use. It must already be installed.
// @param options {sym[]} The fields the parser should return
// @returns {func} A function to parse text
parser.newParser:{[modelName;options]
  opts:{distinct x,raze parser.i.depOpts x}/[options];
  disabled:`ner`tagger`parser except opts;
  model:parser.i.newSubParser[modelName;opts;disabled];
  tokenAttrs:parser.i.q2spacy key[parser.i.q2spacy]inter opts;
  pyParser:parser.i.parseText[model;tokenAttrs;opts;];
  stopWords:(`$.p.list[model`:Defaults.stop_words]`),`$"-PRON-";
  parser.i.runParser[pyParser;options;opts;stopWords]
  }

// @fileOverview Create a new parser
// @param modelName {sym} The spaCy model to use. It must already be installed.
// @param options {sym[]} The fields the parser should return
// @param disables {sym[]} The modules to be disabled
// @returns {func} a parser for the given language
parser.i.newSubParser:{[modelName;options;disabled] 
  checkLang:parser.i.alphalang modelName;
  lang:$[`~checkLang;`spacy;sv[`]`spacy.lang,modelName];
  model:.p.import[lang][hsym$[`~checkLang;`load;checkLang]];
  model:model . raze[$[`~checkLang;modelName;()];`disable pykw disabled];
  if[`sbd in options;
    pipe:$[`~checkLang;model[`:create_pipe;`sentencizer];.p.pyget`x_sbd];
    model[`:add_pipe]pipe;
    ];
  if[`spell in options;
    spacyTokens:.p.import[`spacy.tokens][`:Token];
    if[not spacyTokens[`:has_extension]["hunspell_spell"]`;
      spHun:.p.import[`spacy_hunspell]`:spaCyHunSpell;
      platform:`$.p.import[`platform][`:system][]`;
      osSys:$[`Darwin~platform;`mac;lower platform];
      hunspell:spHun[model;osSys];
      model[`:add_pipe]hunspell
      ]
    ];
  model
  }

// @fileoverview Operations that must be done in q, or give better performance 
//   in q
// @param pyParser {func} A projection to call the spacy parser
// @param colNames {sym[]} The names to give to the fields returned from spacy
// @param options {sym[]} The fields to compute
// @param stopWords {sym[]} The stopWords in the text
// @param docs {str;str[]} The text being parsed
// @returns {dict;tab} The parsed document(s)
parser.i.runParser:{[pyParser;colNames;options;stopWords;docs]
  tab:parser.i.cleanUTF8 each docs;
  parsed:parser.i.unpack[pyParser;options;stopWords]each tab;
  if[`keywords in options;parsed[`keywords]:TFIDF parsed];
  colNames:($[1=count colNames;enlist;]colNames) except `spell;
  colNames#@[parsed;`text;:;tab]
  }

// @fileOverview This handles operations such as casting,or removing punctuation
//  that need to be done in q, or for performance reasons are better in q
// @param pyParser {function} A projection to call the spacy parser
// @param options {symbol[]} The fields to include in the output
// @param stopWords {sym[]} The stopWords in the text
// @param text {string} The text being parsed
// @returns {dictionary} The parsed document
parser.i.unpack:{[pyParser;options;stopWords;text]
  names:inter[key[parser.i.q2spacy],`sentChars`sentIndices;options],`isPunct;
  doc:names!pyParser text;
  // Cast any attributes which should be symbols
  doc:@[doc;names inter`tokens`lemmas`uniPOS`pennPOS;`$];
  // If there are entities, cast them to symbols
  if[`entities in names;doc:.[doc;(`entities;::;0 1);`$]]
  if[`isStop in names;
    if[`uniPOS  in names;doc[`isStop]|:doc[`uniPOS ]in i.stopUniPOS ];
    if[`pennPOS in names;doc[`isStop]|:doc[`pennPOS]in i.stopPennPOS];
    if[`lemmas  in names;doc[`isStop]|:doc[`lemmas ]in stopWords];
    ];
  doc:parser.i.removePunct parser.i.adjustIndices[text]doc;
  if[`sentIndices in options;
    doc[`sentIndices]@:unique:value last each group doc`sentIndices;
    if[`sentChars in opts;doc[`sentChars]@:unique]
  ];
  @[doc;`;:;::]
  }

// Python indexes into strings by char instead of byte, so must be modified to index a q string
parser.i.adjustIndices:{[text;doc]
  adj:cont-til count cont:where ($[1~count text;enlist;]text) within"\200\277";
  if[`starts    in cols doc;doc[`starts   ]+:adj binr 1+doc`starts   ];
  if[`sentChars in cols doc;doc[`sentChars]+:adj binr 1+doc`sentChars];
  doc}

// Removes punctuation and space tokens and updates indices
parser.i.removePunct:{[doc]
  doc:@[doc;key[parser.i.q2spacy]inter k:cols doc;@[;where not doc`isPunct]];
  idx:sums 0,not doc`isPunct;
  if[`sentIndices in k;doc:@[doc;`sentIndices;idx]];
  doc _`isPunct}
