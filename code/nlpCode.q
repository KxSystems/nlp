\d .nlp

// Date-Time

// @kind function
// @category nlp
// @fileoverview Find any times in a string
// @param text {str} A document, potentially containing many times
// @returns {any[]} A list of tuples for each time containing
//   (q-time; timeText; startIndex; 1+endIndex)
findTimes:{[text]
  timeText:regex.matchAll[regex.objects.time;text];
  parseTime:tm.i.parseTime each timeText[;0];
  time:parseTime,'timeText;
  time where time[;0]<24:01
  }

// @kind function
// @category nlp
// @fileoverview Find all the dates in a document
// @param text {str} A document, potentially containing many dates
// @returns {any[]} A list of tuples for each time containing 
//   (startDate; endDate; dateText; startIndex; 1+endIndex)
findDates:{[text]
  ym:regex.matchAll[regex.objects.yearMonth;text];
  ymd:regex.matchAll[regex.objects.yearMonthDay;text];
  convYMD:tm.i.convYearMonthDay each ymd[;0];
  dates:tm.i.rmNull convYMD,'ymd;
  if[count dates;ym@:where not any ym[;1] within/: dates[; 3 4]];
  convYM:tm.i.convYearMonth each ym[;0];
  dates,:tm.i.rmNull convYM,'ym;
  dates iasc dates[;3]
  }

// Parsing function

// @kind function
// @category nlp
// @fileOverview Parse URLs into dictionaries containing the
//   constituent components
// @param url {str} The URL to decompose into its components
// @returns {dict} Contains information about the scheme, domain name 
//   and other URL information
parseURLs:{[url]
  urlKeys:`scheme`domainName`path`parameters`query`fragment;
  urlVals:parser.i.parseURLs url;
  urlKeys!urlVals
  }

// @kind function
// @category nlp
// @fileOverview Create a new parser
// @param spacyModel {sym} The spaCy model/language to use. 
//   This must already be installed.
// @param fieldNames {sym[]} The fields the parser should return
// @returns {func} A function to parse text
newParser:{[spacyModel;fieldNames]
  options:{distinct x,raze parser.i.depOpts x}/[fieldNames];
  disabled:`ner`tagger`parser except options;
  model:parser.i.newSubParser[spacyModel;options;disabled];
  tokenAttrs:parser.i.q2spacy key[parser.i.q2spacy]inter options;
  pyParser:parser.i.parseText[model;tokenAttrs;options;];
  stopWords:(`$.p.list[model`:Defaults.stop_words]`),`$"-PRON-";
  parser.i.runParser[pyParser;fieldNames;options;stopWords]
  }

// Sentiment

// @kind function
// @category nlp
// @fileoverview Calculate the sentiment of a sentence or short message, 
//   such as a tweet
// @param text {str} The text to score
// @returns {dict} The score split up into compound, positive, negative and 
//   neutral components
sentiment:{[text]
  valences:sent.i.lexicon tokens:lower rawTokens:sent.i.tokenize text;
  isUpperCase:(rawTokens=upper rawTokens)& rawTokens<>tokens;
  upperIndices:where isUpperCase & not all isUpperCase;
  valences[upperIndices]+:sent.i.ALLCAPS_INCR*signum valences upperIndices;
  valences:sent.i.applyBoosters[tokens;isUpperCase;valences];
  valences:sent.i.negationCheck[tokens;valences];
  valences:sent.i.butCheck[tokens;valences];
  sent.i.scoreValence[0f^valences;text]
  }

// Comparing docs/terms

// @kind function
// @category nlp
// @fileoverview Calculates the affinity between terms in two corpus' using
//   an Algorithm from Rayson, Paul and Roger Garside.
//   "Comparing corpora using frequency profiling."
//   Proceedings of the workshop on Comparing Corpora. Association for 
//   Computational Linguistics, 2000
// @param corpus1 {tab} A corpus of documents
// @param corpus2 {tab} A corpus of documents  
// @returns {dict[]} A dictionary of terms and their affinities for corpus2 
//   over corpus1
compareCorpora:{[corpus1;corpus2]
  if[not min count each (corpus1;corpus2);:((`$())!();(`$())!())];
  termCountA:i.getTermCount corpus1;
  termCountB:i.getTermCount corpus2;
  totalWordCountA:sum termCountA;
  totalWordCountB:sum termCountB;
  // The expected termCount of each term in each corpus
  coef:(termCountA+termCountB)%(totalWordCountA+totalWordCountB);
  expectedA:totalWordCountA*coef;
  expectedB:totalWordCountB*coef;
  // Return the differences between the corpora
  dict1:desc termCountA*log termCountA%expectedA;
  dict2:desc termCountB*log termCountB%expectedB;
  (dict1;dict2)
  }

// @kind function
// @category nlp
// @fileoverview Calculates the cosine similarity of two documents
// @param keyword1 {dict} A document's keywords
// @param keyword2 {dict} A document's keywords
// @returns {float} The cosine similarity of two documents
compareDocs:{[keyword1;keyword2]
  keywords:distinct raze key each(keyword1;keyword2);
  cosineSimilarity .(keyword1;keyword2)@\:keywords
  }

// @kind function
// @category nlp
// @fileoverview A function for comparing the similarity of two vectors
// @param keywords1 {dict} Keywords and their significance scores 
// @param keywords2 {dict} Keywords and their significance scores 
// @returns {float} Similarity score between -1f and 1f inclusive, 1 being
//   perfectly similar, -1 being perfectly dissimilar
cosineSimilarity:{[keywords1;keywords2]
  sqrtSum1:sqrt sum keywords1*keywords1;
  sqrtSum2:sqrt sum keywords2*keywords2;
  sum[keywords1*keywords2]%(sqrtSum1)*sqrtSum2
  }

// @kind function
// @category nlp
// @fileoverview Calculate how much each term contributes to the 
//   cosine similarity
// @param keywords1 {dict} Keywords and their significance scores 
// @param keywords2 {dict} Keywords and their significance scores 
// @returns {dict} A dictionary of how much of the similarity score each 
//   token is responsible for
explainSimilarity:{[keywords1;keywords2]
  alignedKeys:inter[key keywords1;key keywords2];
  keywords1@:alignedKeys;
  keywords2@:alignedKeys;
  product:(keywords2%i.magnitude keywords1)*(doc2%i.magnitude doc2);
  desc alignedKeys!product%sum product
  }

// @kind function
// @category nlp
// @fileoverview Calculates the cosine similarity of a document and a centroid,
//   subtracting the document from the centroid.
//   This does the subtraction after aligning the keys so that terms not in 
//   the centroid don't get subtracted.
//   This assumes that the centroid is the sum, not the avg, of the documents
//   in the cluster
// @param centroid {dict} The sum of all documents in a cluster
// @param doc {dict} A document in the cluster
// @returns {float} The cosine similarity of a document and centroid
compareDocToCentroid:{[centroid;doc]
  doc@:alignedKeys:distinct key[centroid],key doc;
  vec:centroid[alignedKeys]-doc;
  cosineSimilarity[doc;vec]
  }

// @kind function
// @category nlp
// @fileoverview Find the cosine similarity between one document and all the
//   other documents of the corpus
// @param keywords {dict[]} A list of dictionaries of keywords and coefficients
// @param idx {num} The index of the feature vector to compare to the rest of
//   the corpus
// @returns {float[]} The document's significance to the rest of the corpus
compareDocToCorpus:{[keywords;idx]
  compareDocs[keywords idx]each(idx+1)_ keywords
  }

// @kind function
// @category nlp
// @fileoverview Calculate the Jaro-Winkler distance of two strings
// @param str1 {str;str[]} A string of text
// @param str2 {str;str[]} A string of text
// @returns {float} The Jaro-Winkler of two strings, between 0 and 1
jaroWinkler:{[str1;str2]
  str1:lower str1;
  str2:lower str2;
  jaroScore:i.jaro[str1;str2];
  jaroScore+$[0.7<jaroScore;
    (sum mins(4#str1)~'4#str2)*.1*1-jaroScore;
    0
    ]
  }

// Feature Vectors

// @kind function
// @category nlp
// @fileoverview Generate a feature vector (of stemmed tokens) for a term
// @param corpus {tab} A corpus of documents
// @param term {sym} The tokens to find related terms for
// @returns {dict} The related tokens and their relevances
findRelatedTerms:{[corpus;term]
  term:lower term;
  stopWords:where each corpus`isStop;
  sent:raze corpus[`sentIndices]cut'@'[corpus[`tokens];stopWords;:;`];
  sent@:asc distinct raze 0|-1 0 1+\:where term in/:sent;
  // The number of sentences the term co-occurs in
  coOccur:` _ count each group raze distinct each sent;
  idx:where each corpus[`tokens]in\:key coOccur;
  // Find how many sentences each word occurs in
  totOccur:idx@'group each corpus[`tokens]@'idx;
  sentInd:corpus[`sentIndices]bin'totOccur;
  totOccur:i.fastSum((count distinct@)each)each sentInd;
  coOccur%:totOccur term;
  totOccur%:sum count each corpus`sentIndices;
  results:(coOccur-totOccur)%sqrt totOccur*1-totOccur;
  desc except[where results>0;term]#results
  }

// @kind function
// @category nlp
// @fileoverview Find runs containing term where each word has above average 
//   co-ocurrance with a provided term
// @param corpus {tab} A corpus of documents
// @param term {sym} The term to extract phrases around
// @returns {dict} Phrases as the keys, and their relevance as the values
extractPhrases:{[corpus;term]
  term:lower term;
  tokens:corpus`tokens;
  related:findRelatedTerms[corpus]term;
  // This gets the top words that have an above average relavance to the 
  // query term
  relevant:term,sublist[150]where 0<related;
  // Find all of the term's indices in the corpus
  runs:(i.findRuns where@)each tokens in\:relevant;
  tokenRuns:raze tokens@'runs;
  phrases:count each group tokenRuns where term in/:tokenRuns;
  desc(where phrases>1)#phrases
  }

// @kind function
// @category nlp
// @fileoverview Given an input which is conceptually a single document,
//   such as a book, this will give better results than TF-IDF.
//   This algorithm is explained in the paper Carpena, P., et al.
//   "Level statistics of words: Finding keywords in literary texts
//    and symbolic sequences."
//   Physical Review E 79.3 (2009): 035102.
// @param docs {tab} A collection of documents 
// @returns {dict} Where the keys are keywords as symbols, and the values are 
//   their significance, as floats,with higher values being more significant
keywordsContinuous:{[docs]
  text:raze docs[`tokens]@'where each not docs`isStop;
  groupTxt:group text;
  n:count each groupTxt;
  // Find the distinct words, ignoring stop words and those with 3 or fewer 
  // occurences, or make up less than .002% of the corpus
  words:where n>=4|.00002*count text;
  // Find the distances between occurences of the same word
  // and use this to generate a 'sigma value' for each word
  dist:deltas each words#groupTxt;
  n:words#n;
  sigma:(dev each dist)%(avg each dist)*sqrt 1-n%count text;
  stdSigma:1%sqrt[n]*1+2.8*n xexp -0.865;
  chevSigma:((2*n)-1)%2*n+1;
  desc(sigma-chevSigma)%stdSigma
  }

// @kind function
// @category nlp
// @fileoverview Find the TF-IDF scores for all terms in all documents
// @param corpus {tab} A table of documents
// @returns {dict[]} For each document, a dictionary with the tokens as keys,
//   and relevance as values
TFIDF:{[corpus]
  nums:corpus[`tokens]like\:"[0-9]*";
  tokens:corpus[`tokens]@'where each not corpus[`isStop]|nums;
  words:distinct each tokens;
  // The term frequency of each token within the document
  TF:{x!{sum[x in y]%count x}[y]each x}'[words;tokens];
  // Calculate the inverse document frequency
  IDF:1+log count[tokens]%{sum{x in y}[y]each x}[tokens]each words;
  TF*IDF
  }

// Exploratory Analysis 

// @kind function
// @category nlp
// @fileoverview Find runs of tokens whose POS tags are in the set passed in
// @param tagType {sym} `uniPOS or `pennPOS (Universal or Penn Part-of-Speech)
// @param tags {sym;sym[]} One or more POS tags
// @param doc {dict} A single document
// @returns {(str;long)} Two item list containing
//   1. The text of the run as a symbol vector
//   2. The index associated with the first token
findPOSRuns:{[tagType;tags;doc]
  matchingTag:doc[tagType]in tags;
  start:where 1=deltas matchingTag;
  lengths:sum each start cut matchingTag;
  idx:start+til each lengths; 
  runs:`$" "sv/:string each doc[`tokens]start+til each lengths;
  flip(runs;idx)
  }

// @kind function
// @category nlp
// @fileoverview Determine the probability of one word following another
//   in a sequence of words
// @param corpus {tab} A corpus of documents
// @returns {dict} The probability that the secondary word in the sequence 
//   follows the primary word.
biGram:{[corpus]
  nums:corpus[`tokens]like\:"[0-9]*";
  tokens:raze corpus[`tokens]@'where each not corpus[`isStop]|nums;
  occurance:(distinct tokens)!{count where y=x}[tokens]each distinct tokens;
  raze i.biGram[tokens;occurance]''[tokens;next tokens]
  }

// Util 

// @kind function
// @category nlp
// @fileoverview Find Regular expressions within texts
// @param text {str[]} The text of a document
// @param expr {sym} The expression type to be searched for within the text
findRegex:{[text;expr]
  nExpr:$[1=count expr;enlist;];
  regexKeys:nExpr expr;
  regexVals:nExpr{regex.matchAll[regex.objects[x];y]}[;text]each expr;
  regexKeys!regexVals
  }

// @kind function
// @category nlp
// @fileoverview Remove any non-ascii characters from a text
// @param text {str} A string of text
// @returns {str} Non-ascii characters removed from the text
removeNonAscii:{[text]
  text where text within (0;127)
  }

// @kind function
// @category nlp
// @fileoverview Remove certain characters from a string of text
// @param text {str} A string of text
// @param char {str[]} Characters or expressions to be removed from the text 
// @returns {str} The text without anything that contains the defined 
//   characters
removeCustom:{[text;char]
  vecText:" " vs text;
  rtrim raze(vecText where{not(max ,'/)x like/:y}[;char]each vecText),'" "
  }

// @kind function
// @category nlp
// @fileoverview Remove and replace certain characters from a string of text
// @param text {str} A string of text
// @param char {str[]} Characters or expressions to be removed from the text 
// @param replace {str} The characters which will replace the removed
//   characters
removeReplace:{[text;char;replace]
  {x:ssr[x;y;z];x}[;;replace]/[text;char]
  }

// @kind function
// @category nlp
// @fileoverview Detect language from text
// @param text {str} A string of text
// @returns {sym} The language of the text
detectLang:{[text]
  `$.p.import[`langdetect][`:detect;<][text]
  }

// @kind function
// @category nlp
// @fileoverview Import all files in a directory recursively
// @param filepath {str} The directories file path
// @returns {tab} Filenames, paths and texts contained within the filepath
loadTextFromDir:{[filepath]
  filepath:hsym`$filepath;
  keyFilepath:key filepath;
  path:{raze$[11=abs type keyPath:key x;x;.z.s each` sv'x,'keyPath]}filepath;
  ([]fileName:(` vs'path)[;1];path;text:"\n"sv'read0 each path)
  }

// @kind function
// @category nlp
// @fileOverview Get all the sentences for a document
// @param doc {dict} A document record
// @returns {str[]} All the sentences from a document
getSentences:{[doc]
  (sublist[;doc`text]deltas@)each doc`sentChars
  }

// @kind function
// @category nlp
// @fileoverview Determine the probability of a `n` tokens appearing together
//   in a text
// @param corpus {tab} A corpus of documents
// @param n {long} The number of words to occur together
// @returns {dict} The probability that the next `n` tokens in the sequence 
//   follows the primary word.
nGram:{[corpus;n]
  nums:corpus[`tokens]like\:"[0-9]*";
  tokens:raze corpus[`tokens]@'where each not corpus[`isStop]|nums;
  tab:rotate\:[til n]tokens;
  nGroup:last[tab]group neg[n-1]_flip(n-1)#tab;
  occurance:{(count each group x)%count x}each nGroup;
  returnKeys:raze key[occurance],/:'{key x}each value occurance;
  returnVals:raze value each value occurance;
  returnKeys!returnVals
  }
