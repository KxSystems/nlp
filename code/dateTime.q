\d .nlp

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Pads a string containing a single integer to two digits
//   or extracts the last 2 digits from a string
// @param day {str} Contains a date
// @returns {str} Padded date to two digits
tm.i.parseDay:{[day]
  -2#"0",day where day in .Q.n
  }

// @private
// @kind data
// @category nlpTimeUtility
// @fileoverview Dictionary mapping the months of the year 
//   to a symbol denoting integer representation
tm.i.months:`jan`feb`mar`apr`may`jun`jul`aug`sep`oct`nov`dec!`$string 1+til 12

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Convert a long-form or short-form month string to 
//   a string denoting the month as an integer "feb"/"february"
//   become "02"
// @param day {str} A month of the year in English
// @returns {str} A padded integer representing the month of the year
tm.i.parseMonth:{[month]
  -2#"0",string month^tm.i.months month:lower`$3 sublist month
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Pad a string denoting a year to 4 digits
//   if input > 35 this is deemed to be 1900s 
//   i.e. "20" -> "2020" / "44" -> "1944")
// @param year {str} Contains a year
// @returns {str} Padded year value
tm.i.parseYear:{[year]
  -4#$[35<"I"$-2#year;"19";"20"],year
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Convert year string to the entire date
//   encapsulating that year
// @param year {str} A year 
// @returns {str} Date range from Jan 1 to Dec 31 of
//   the specified year
tm.i.convY:{[year]
  "D"$year,/:(".01.01";".12.31")
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Convert string containing yearMonth
//   to the date range encapsulating that month
//   i.e. "test 2020.02" -> 2020.02.01 2020.02.29
//        "2019.02 test" -> 2019.02.01 2019.02.28
// @param text {str} Text containing yearMonth value
// @returns {str} Date range for the month of the
//   provided yearMonth
tm.i.convYearMonth:{[text]
  txt:regex.matchAll[;text]each regex.objects`year`month;
  matches:ungroup([format:"ym"]txt);
  updMatches:matches,'flip`txt`s`e!flip matches`txt;
  matches:value select format,last txt by s from updMatches;
  format:tm.i.formatYM/[matches`format];
  format:raze@[format;i where 1<count each i:group format;:;" "];
  0 -1+"d"$0 1+"M"$"."sv tm.i[`parseYear`parseMonth]@'matches[`txt]idesc format
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Seperate YearMonth formats to year and month
//   i.e "ym" -> "y","m"
// @params ym {str[]} The format for each date objecct
// @returns {str} Formats of YearMonths objects seperated
tm.i.formatYM:{[ym]
  @[ym;where not counts;except[;raze ym where counts:1=count each ym]]
  }

// @private
// @kind function
// @category nlpTimeUtility
// fileoverview Convert string containing yearMonthDay
//   to the date range encapsulating that day
//   i.e. "test 2020.01.01" -> 2020.01.01 2020.01.01
//        "2010.01.01 test" -> 2010.01.01 2010.01.01
// @param text {str} Text containing yearMonthDay value 
// @returns {str} Date range associated with the
//   provided yearMonthDay
tm.i.convYearMonthDay:{[text]
  txt:regex.matchAll[;text]each regex.objects`year`month`day;
  matches:ungroup([format:"ymd"]txt);
  updMatches:matches,'flip`txt`s`e!flip matches`txt;
  matches:value select format,last txt by s from updMatches;
  format:tm.i.formatYMD/[matches`format];
  format:tm.i.resolveFormat raze@[format;where 1<count each format;:;" "];  
  2#"D"$"."sv tm.i[`parseYear`parseMonth`parseDay]@'matches[`txt]idesc format
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Seperate YearMonth formats to year and month
//   i.e "ymd" -> "y","m","d"
// @params ymd {str[]} The format for each date objecct
// @returns {str} Formats of YearMonthDays objects seperated
tm.i.formatYMD:{[ymd]
  @[ymd;i unq;:;"ymd" unq:where 1=count each i:where each "ymd" in/:\:ymd]
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Fill in the blanks in a date format string
// @param format {str} A date format, as some permutation of "d", "m", and "y"
// @returns {str} The date format with any blanks filled with their most
//   plausible value
tm.i.resolveFormat:{[format]
  $[0=n:sum" "=format;
      ;
    1=n;
      ssr[;" ";first"ymd"except format];
    2=n;
      tm.i.dateFormats;
    {"dmy"}
   ]format
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview The format to use, given a single known position
tm.i.dateFormats:(!). flip(
  ("d  ";"dmy"); // 10th 02 99
  ("m  ";"mdy"); // Feb 10 99
  ("y  ";"ymd"); // 1999 02 10
  (" d ";"mdy"); // 02 10th 99
  (" m ";"dmy"); // 10 Feb 99
  (" y ";"dym"); // 10 1999 02 This is never conventionally used
  ("  d";"ymd"); // 99 02 10th
  ("  m";"ydm"); // 99 10 Feb This is never conventionally used
  ("  y";"dmy")) // 10 02 1999 //mdy is the american option

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Turns a regex time string into a q timestamp
//   i.e "131030" -> 13:10:30.000
//       "1pm"    -> 13:00:00.000
// @param text {str} A time string
// @returns {timestamp} The q time parsed from an
//   appropriate string
tm.i.parseTime:{[text]
  numText:vs[" ";text][0]in"1234567890:.";
  time:"T"$text where numText; 
  amPM:regex.i.check[;text]each regex.objects`am`pm;
  time+$[amPM[0]&12=`hh$time;-1;amPM[1]&12>`hh$time;1;0]*12:00
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Remove any null values
// @array {num[][]} Array of values
// returns {num[][]} Array with nulls removed
tm.i.rmNull:{[array]
  array where not null array[;0]
  }
