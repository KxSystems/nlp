\d .nlp
\l p.q
{.p.import[`sys;x][:;`:write;{x y;count y}y]}'[`:stdout`:stderr;1 2]; / redundant in latest embedPy
i.np:.p.import`numpy
i.str:.p.import[`builtins]`:str
i.bool:.p.import[`builtins]`:bool

// Fast sum list of dicts (3 experimentally determined optimal number iterations)
i.fastSum:{[it;d]sum$[it;.z.s it-1;sum]each(ceiling sqrt count d)cut d}2

// Replace empty dicts with (,`)!,0f 
i.fillEmptyDocs:{[docs]$[98=type docs;0^docs;@[docs;i;:;count[i:where not count each docs]#enlist(1#`)!1#0f]]}

// Given monotonic increasing int list, return runs of consecutive numbers
i.findRuns:{(where x<>1+prev x)_ x@:where r|:next r:x=1+prev x}

// Get all sentences for doc
i.getSentences:{[doc](sublist[;doc`text]deltas@)each doc`sentChars}

// Index of min element
i.minIndex:{x?min x}

// Index of max element
i.maxIndex:{x?max x}

// Calc harmonic mean
i.harmonicMean:{1%avg 1%x}

// Calc a vector's magnitude
i.magnitude:{sqrt sum x*x}

// Normalize list or dict so the highest value is 1f
i.normalize:{x%max x}

// Take largest N values
i.takeTop:{[n;x]n sublist desc x}

// Jaro distance of 2 strings
i.jaro:{[s1;s2]
  if[0=l1:count s1;:0f];
  d:1|-1+floor .5*l1|l2:count s2;
  k:l[0]+where each s1='sublist\:[flip l:deltas 0|til[l1]+/:(-1 1)*d]s2;
  m:count i:$[1=count j:k[0;0]{x,(y except x)0}/1_k;where not null j:enlist[j];where not null j];
  t:.5*sum s1[i]<>s2 asc j i;
  avg(m%l1;m%l2;(m-t)%m)}

// Jaro-Winkler distance of 2 strings
i.jaroWinkler:{$[0.7<w:i.jaro[x;y];w+(sum mins(4#x)~'4#y)*.1*1-w;w]}

// Generating symmetric matrix from triangle (ragged list)
i.matrixFromRaggedList:{m+flip m:((til count x)#'0.),'.5,'x}

// Parts-of-speech not useful as keywords
i.stopUniPOS:asc`ADP`PART`AUX`CONJ`DET`SYM`NUM`PRON`SCONJ
i.stopPennPOS:asc`CC`CD`DT`EX`IN`LS`MD`PDT`POS`PRP`SYM`TO`WDT`WP`WRB`,`$("PRP$";"WP$";"$") /add in ` for symbols

// Calc cosine similarity between doc and entire corpus
i.compareDocToCorpus:{[keywords;idx]compareDocs[keywords idx]each(idx+1)_ keywords}

// @private
// @kind function
// @category nlpUtility
// @fileoverview Get the count of terms in a corpus
// @params corpus {tab} A corpus of documents
// @returns {dict} The count of terms in the corpus
i.getTermCount:{[corpus]
  tokens:corpus[`tokens]@'where each not corpus`isStop;
  i.fastSum{1+log count each group x}each tokens
  }

// @kind function
// @category nlp
// @fileoverview Calculate the probability of words appearing in a text
// @param tokens {sym[]} The tokens in the text
// @param occurance {dict} The total times a token appears in the text
// @param token {sym} A single token
// @param nextToken {sym} The next token in the list of tokens
// @returns {dict} The probability that the secondary word in the sequence 
//   follows the primary word.
i.biGram:{[tokens;occurance;token;nextToken]
  returnKeys:enlist(token;nextToken);
  countToken:count where nextToken=tokens 1+where token=tokens;
  returnVals:countToken%occurance[token];
  returnKeys!enlist returnVals
  }
