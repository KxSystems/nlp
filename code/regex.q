\d .nlp

// @private
// @kind function
// @category nlpRegexUtility
// @fileoverview Import regex modul from python
regex.i.re:.p.import`re

// @private
// @kind function
// @category nlpRegexUtility
// @fileoverview Check if a pattern occurs in the text
// @params patterns {<} A regex pattern as an embedPy object
// @params text {str} A piece of text t
// @returns {bool} Indicate whether or not the pattern is present in the text 
regex.i.check:{[patterns;text]
  i.bool[patterns[`:search]text]`
  }

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of special characters
regex.i.patterns.specialChars:"[-[\\]{}()*+?.,\\\\^$|#\\s]"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of special characters
regex.i.patterns.money:"[$¥€£¤฿]?\\s*((?<![.0-9])([0-9][0-9, ]*(\\.",
  "([0-9]{0,2})?)?|\\.[0-9]{1,2})(?![.0-9]))\\s*((hundred|thousand|million",
  "|billion|trillion|[KMB])?\\s*([$¥€£¤฿]|dollars?|yen|pounds?|cad|usd|gbp",
  "|eur))|[$¥€£¤฿]\\s*((?<![.0-9])([0-9][0-9, ]*(\\.([0-9]{0,2})?)?|\\.",
  "[0-9]{1,2})(?![.0-9]))\\s*((hundred|thousand|million|billion|trillion|",
  "[KMB])\\s*([$¥€£¤฿]|dollars?|yen|pounds?|cad|usd|gbp|eur)?)?"


// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of phone number characters
regex.i.patterns.phoneNumber:"\\b((\\+?\\s*\\(?[0-9]+\\)?[-. /]?)?\\(?[0-9]+",
  "\\)?[-. /]?)?[0-9]{3}[-. ][0-9]{4}(\\s*(x|ext\\s*.?|extension)[ .-]*[0-9]",
  "+)?\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of email address characters
regex.i.patterns.emailAddress:"\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of url characters
regex.i.patterns.url:"((https?|ftps?)://(www\\d{0,3}\\.)?|www\\d{0,3}\\.)",
  "[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/))"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of zipcode characters
regex.i.patterns.zipCode:"\\b\\d{5}\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of postal code characters
regex.i.patterns.postalCode:"\\b[a-z]\\d[a-z] ?\\d[a-z]\\d\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of postal or zip code characters
regex.i.patterns.postalOrZipCode:"\\b(\\d{5}|[a-z]\\d[a-z] ?\\d[a-z]\\d)\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of date seperator characters
regex.i.patterns.dateSeperate:"[\\b(of |in )\\b\\t .,-/\\\\]+"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of date characters
regex.i.patterns.day:"\\b[0-3]?[0-9](st|nd|rd|th)?\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of monthly characters
regex.i.patterns.month:"\\b([01]?[0-9]|jan(uary)?|feb(ruary)?|mar(ch)?|",
  "apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|nov(ember)?",
  "|dec(ember)?)\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of yearly characters
regex.i.patterns.year:"\\b([12][0-9])?[0-9]{2}\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of year characters in full
regex.i.patterns.yearFull:"\\b[12][0-9]{3}\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of am characters
regex.i.patterns.am:"(a[.\\s]?m\\.?)"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of pm characters
regex.i.patterns.pm:"(p[.\\s]?m\\.?)"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of time (12hr) characters
regex.i.patterns.time12:"\\b[012]?[0-9]:[0-5][0-9](h|(:[0-5][0-9])([.:][0-9]",
  "{1,9})?)?\\s*(",sv["|";regex.i.patterns`am`pm],")?\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of time (24hr) characters
regex.i.patterns.time24:"\\b[012][0-9][0-5][0-9]h\\b"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of all time characters
regex.i.patterns.time:"(",sv["|";regex.i.patterns`time12`time24],")"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of year/month characters as a list
regex.i.patterns.yearMonthList:"(",sv["|";regex.i.patterns`year`month],")"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of year/month/date characters
regex.i.patterns.yearMonthDayList:"(",sv["|";
  regex.i.patterns`year`month`day],")"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of year/month characters along with date seperators
regex.i.patterns.yearMonth:"(",sv[regex.i.patterns.dateSeperate;
  2#enlist regex.i.patterns.yearMonthList],")"

// @private
// @kind data
// @category nlpRegexUtilityPattern
// @fileoverview A string of year/month/date characters along with date
//   seperators
regex.i.patterns.yearMonthDay:"(",sv[regex.i.patterns.dateSeperate;
  3#enlist regex.i.patterns.yearMonthDayList],")"

// @kind function
// @category nlpRegex
// @fileoverview Compile a regular expression pattern into a regular 
//   expression embedPy object which can be used for matching
// @params patterns {str} A regex pattern
// @params ignoreCase {bool} Whether the case of the string is to be ignored
// @returns {<} The compiled regex object
regex.compile:{[patterns;ignoreCase]
  case:$[ignoreCase;regex.i.re`:IGNORECASE;0];
  regex.i.re[`:compile;patterns;case]
  }

// @kind function
// @category nlpRegex
// @fileoverview Finds all the matches in a string of text
// @params patterns {<} A regex pattern as an embedPy object
// @params text {str} A piece of text
// @returns {null;str[]} If the pattern is not present in the text a null
//   is returned. Otehrwise, the pattern along with the index where the 
//   pattern begins and ends is returned
regex.matchAll:.p.eval["lambda p,t:[[x.group(),x.start(),x.end()]",
  "for x in p.finditer(t)]";<]

// @kind function
// @category nlpRegex
// @fileoverview Compile all patterns into regular expression objects
regex.objects:regex.compile[;1b]each 1_regex.i.patterns
