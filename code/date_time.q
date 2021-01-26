\d .nlp

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Pads a string containing a date to two digits
// @param day {str} Contains a date
// @returns {str} Padded date to two digits
tm.i.parseDay:{[day]
  -2#"0",day where day in .Q.n
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview The months of the year
tm.i.months:`jan`feb`mar`apr`may`jun`jul`aug`sep`oct`nov`dec!`$string 1+til 12

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Pads a string containing a month to two digits
// @param day {str} Contains a month
// @returns {str} Padded month string
tm.i.parseMonth:{[month]
  -2#"0",string month^tm.i.months month:lower`$3 sublist month
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Pad year string to 4 digits (>35 deemed 1900s)
// @param year {str} Contains a year
// @returns {str} Padded year value
tm.i.parseYear:{[year]
  -4#$[35<"I"$-2#year;"19";"20"],year
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Convert year string to date range
// @param year {str} A year value
// @returns {str} Date range
tm.i.convY:{[year]
  "D"$year,/:(".01.01";".12.31")
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Convert yearMonth string to date range
// @param text {str} Contains yearMonth value
// @returns {str} yearMonth value as a date range
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
// @fileoverview Extract formats of dates (YearMonth)
// @params ym {str[]} The format for each date object
// @returns {str} Formats of dates 
tm.i.formatYM:{[ym]
  @[ym;where not counts;except[;raze ym where counts:1=count each ym]]
  }

// @private
// @kind function
// @category nlpTimeUtility
// fileoverview Convert yearMonthDay string to date range
// @param text {str} Contains yearMonthDay value
// @returns {str} yearMonthDay as a date range
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
// @fileoverview Extract formats of dates (YearMonthDay)
// @params ymd {str[]} The format for each date object
// @returns {str} Formats of dates 
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
tm.i.dateFormats:(!). flip( / format given single known position
  ("d  ";"dmy"); // 2nd 12 12
  ("m  ";"mdy"); // Jan 12 12
  ("y  ";"ymd"); // 1999 12 12
  (" d ";"mdy"); // 12 2nd 12
  (" m ";"dmy"); // 12 Jan 12
  (" y ";"dym"); // 12 1999 12 This is never conventionally used
  ("  d";"ymd"); // 12 12 2nd
  ("  m";"ydm"); // 12 12 Jan This is never conventionally used
  ("  y";"dmy")) // 12 12 1999 //mdy is the american option

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Turns a string matching the time regex into a q time
// @param text {str} A string that matches the time regex
// @returns {minute[];second} The value from the string as a q time
tm.i.parseTime:{[text]
  numText:vs[" ";text][0]in"1234567890:.";
  time:"T"$text where numText; 
  amPM:regex.check[;text]each regex.objects`am`pm;
  time+$[amPM[0]&12=`hh$time;-1;amPM[1]&12>`hh$time;1;0]*12:00
  }

// @private
// @kind function
// @category nlpTimeUtility
// @fileoverview Remove any null values
// @array {num[][]} array of values
// returns {num[][]} Array with nulls removed
tm.i.rmNull:{[array]
  array where not null array[;0]
  }

// @kind function
// @category nlpTime
// @fileoverview Find any times in a string
// @param text {str} A document, potentially containing many times
// @returns {any[]} A list of 4 tuples (time; timeText; startIndex; 1+endIndex)
tm.findTimes:{[text]
  timeText:regex.matchAll[regex.objects.time;text];
  parseTime:tm.i.parseTime each timeText[;0];
  time:parseTime,'timeText;
  time where time[;0]<24:01
  }

// @kind function
// @category nlpTime
// @fileoverview Find all the dates in a document
// @param text {str} A document, potentially containing many dates
// @returns {any[]} A list of 5-tuples 
//   (startDate; endDate; dateText; startIndex; 1+endIndex)
tm.findDates:{[text]
  ym:regex.matchAll[regex.objects.yearmonth;text];
  ymd:regex.matchAll[regex.objects.yearmonthday;text];
  convYMD:tm.i.convYearMonthDay each ymd[;0];
  dates:tm.i.rmNull convYMD,'ymd;
  if[count dates;ym@:where not any ym[;1] within/: dates[; 3 4]];
  convYM:tm.i.convYearMonth each ym[;0];
  dates,:tm.i.rmNull convYM,'ym;
  dates iasc dates[;3]
  }
