\d .nlp

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Retrieve python function for running spacy
parser.i.parseText:.p.get[`get_doc_info;<];

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Retrieve python function to decode bytes
parser.i.cleanUTF8:.p.import[`builtins;`:bytes.decode;<]
  [;`errors pykw`ignore]$["x"]@;

// @private
// @kind data
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
// @kind data
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
// @kind data
// @category nlpParserUtility
// @fileoverview Model inputs for spacy 'alpha' models
parser.i.alphaLang:(!). flip(
  (`ja;`Japanese);
  (`zh;`Chinese))

// @private
// @kind function
// @category nlpParser
// @fileOverview Create a new parser
// @param modelName {sym} The spaCy model/language to use. 
//   This must already be installed.
// @param options {sym[]} The fields the parser should return
// @param disabled {sym[]} The modules to be disabled
// @returns {func} a parser for the given language
parser.i.newSubParser:{[modelName;options;disabled] 
  checkLang:parser.i.alphaLang modelName;
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

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Parser operations that must be done in q, or give better 
//   performance in q
// @param pyParser {func} A projection to call the spacy parser
// @param fieldNames {sym[]} The field names the parser should return
// @param options {sym[]} The fields to compute
// @param stopWords {sym[]} The stopWords in the text
// @param docs {str;str[]} The text being parsed
// @returns {dict;tab} The parsed document(s)
parser.i.runParser:{[pyParser;fieldNames;options;stopWords;docs]
  tab:parser.i.cleanUTF8 each docs;
  parsed:parser.i.unpack[pyParser;options;stopWords]each tab;
  if[`keywords in options;parsed[`keywords]:TFIDF parsed];
  fieldNames:($[1=count fieldNames;enlist;]fieldNames) except `spell;
  fieldNames#@[parsed;`text;:;tab]
  }

// @private
// @kind function
// @category nlpParserUtility
// @fileOverview This handles operations such as casting/removing punctuation
//   that need to be done in q, or for performance reasons are better in q
// @param pyParser {func} A projection to call the spaCy parser
// @param options {sym[]} The fields to include in the output
// @param stopWords {sym[]} The stopWords in the text
// @param text {str} The text being parsed
// @returns {dict} The parsed document
parser.i.unpack:{[pyParser;options;stopWords;text]
  names:inter[key[parser.i.q2spacy],`sentChars`sentIndices;options],`isPunct;
  doc:names!pyParser text;
  // Cast any attributes which should be symbols
  doc:@[doc;names inter`tokens`lemmas`uniPOS`pennPOS;`$];
  // If there are entities, cast them to symbols
  if[`entities in names;doc:.[doc;(`entities;::;0 1);`$]]
  if[`isStop in names;
    if[`uniPOS in names;doc[`isStop]|:doc[`uniPOS]in i.stopUniPOS];
    if[`pennPOS in names;doc[`isStop]|:doc[`pennPOS]in i.stopPennPOS];
    if[`lemmas in names;doc[`isStop]|:doc[`lemmas]in stopWords];
    ];
  doc:parser.i.removePunct parser.i.adjustIndices[text]doc;
  if[`sentIndices in options;
    doc[`sentIndices]@:unique:value last each group doc`sentIndices;
    if[`sentChars in options;doc[`sentChars]@:unique]
    ];
  @[doc;`;:;::]
  }

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview This converts python indices to q indices in the text
//   This has to be done because python indexes into strings by char instead 
//   of byte, so must be modified to index a q string
// @param text {str} The text being parsed
// @param doc {dict} The parsed document
// @returns {dict} The document with corrected indices
parser.i.adjustIndices:{[text;doc]
  if[1~count text;text:enlist text];
  // Any bytes following the first byte in UTF-8 multi-byte characters
  // will be in the range 128-191. These are continuation bytes.
  continuations: where text within "\200\277";
  // To find a character's index in python,
  // the number of previous continuation bytes must be subtracted
  adjusted:continuations-til count continuations;
  // Add to each index the number of continuation bytes which came before it
  // This needs to add 1, as the string "“hello”" gives the 
  // adjustedContinuations 1 1 7 7.
  // If the python index is 1, 1 1 7 7 binr 1 gives back 0, so it needs to 
  // check the index after the python index
  if[`starts in cols doc;doc[`starts]+:adjusted binr 1+doc`starts];
  if[`sentChars in cols doc;doc[`sentChars]+:adjusted binr 1+doc`sentChars];
  doc
  }

// @private
// @kind function
// @category nlpParserUtility
// @fileoverview Removes punctuation and space tokens and updates indices
// @param doc {dict} The parsed document
// @returns {dict} The parsed document with punctuation removed
parser.i.removePunct:{[doc]
  // Extract document attributes
  attrs:cols doc;
  doc:@[doc;key[parser.i.q2spacy]inter attrs;@[;where not doc`isPunct]];
  idx:sums 0,not doc`isPunct;
  if[`sentIndices in attrs;doc:@[doc;`sentIndices;idx]];
  doc _`isPunct
  }

// @kind function
// @category nlpParserUtility
// @fileOverview Create a new parser
// @param modelName {sym} The spaCy modeli/language to use. 
//   This must already be installed.
// @param fieldNames {sym[]} The fields the parser should return
// @returns {func} A function to parse text
parser.newParser:{[modelName;fieldNames]
  options:{distinct x,raze parser.i.depOpts x}/[fieldNames];
  disabled:`ner`tagger`parser except options;
  model:parser.i.newSubParser[modelName;options;disabled];
  tokenAttrs:parser.i.q2spacy key[parser.i.q2spacy]inter options;
  pyParser:parser.i.parseText[model;tokenAttrs;options;];
  stopWords:(`$.p.list[model`:Defaults.stop_words]`),`$"-PRON-";
  parser.i.runParser[pyParser;fieldNames;options;stopWords]
  }
