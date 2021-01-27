\d .nlp

//Loading python script to extract rtf text
system"l ",.nlp.path,"/","code/extract_rtf.p";

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Regular expression function imported from python
i.striprtf:.p.get[`striprtf;<]

// @kind function
// @category nlpEmail
// @fileoverview Read an mbox file, converting it to a table with the parsed 
//   metadata and the content as plain-text
// @param filepath {str} The path to the mbox
// @returns {tab} Parsed metadata and content from the mbox
email.getMboxText:{[filepath]
  parseMbox:email.i.parseMbox filepath;
  update text:.nlp.email.i.extractText each payload from parseMbox
  }

// @kind function
// @category nlpEmail
// @fileoverview Get the graph of who emailed who, including the number of 
//   times they emailed
// @param emails {tab} The result of .nlp.loadEmails
// @returns {tab} Defines to-from pairings of emails
email.getGraph:{[emails]
  getToFrom:flip`$raze email.i.getToFrom each emails;
  getToFromTab:flip`sender`to!getToFrom;
  0!`volume xdesc select volume:count i by sender,to from getToFromTab
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract information from various message text types
// @params textTyp {str} The format of the message text 
// @param msg {str;dict} An email, or email subtree
// @returns {bool} Whether or not msg fits the text type criteria 
email.i.findMime:{[textTyp;msg]
  msgDict:99=type each msg`payload;
  contentTyp:textTyp~/:msg`contentType;
  attachment:0b~'msg[`payload]@'`attachment;
  all(msgDict;contentTyp;attachment)
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Use beautiful soup to extract text from a html file
// @param msg {str} The message payload
// @returns {str} The text from the html
email.i.html2text:{[msg]
  email.i.bs[msg;"html.parser"][`:get_text;"\\n"]`
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Given an email, extract the text of the email
// @param msg {str;dict} An email, or email subtree
// @returns {str} The text of the email, or email subtree
email.i.extractText:{[msg]
  // String is actual text, bytes attachment or non text mime type like inline 
  // image, dict look at content element
  msgType:type msg;
  if[10=msgType;:msg];
  if[4=msgType;:""];
  if[99=msgType;:.z.s msg`content];
  findMime:email.i.findMime[]msg;
  text:$[count i:where findMime["text/plain"];
      {x[y][`payload]`content}[msg]each i;
    count i:where findMime["text/html"];
      {email.i.html2text x[y][`payload]`content}[msg]each i;
    count i:where findMime["application/rtf"];
      // Use python script to extract text from rtf
      {i.striprtf x[y][`payload]`content}[msg]each i;
    .z.s each msg`payload
    ];
  "\n\n"sv text
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Get all the to/from pairs from an email
// @param msg {dict} An email message, or subtree thereof
// @returns {any[]} To/from pairings of an email
email.i.getToFrom:{[msg]
  payload:msg`payload;
  payload:$[98=type payload;raze .z.s each payload;()];
  edges:(msg[`sender;0;1];)each msg[`to;;1];
  edges,payload
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the sender information from an email
// @param msg {<} The email as an embedPy object
// @returns {str[]} Sender name and email
email.get.i.sender:{[msg]
  fromInfo:raze msg[`:get_all;<]each("from";"resent-from");
  email.i.getAddr fromInfo where not(::)~'fromInfo
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the receiver information from an email
// @param msg {<} The email as an embedPy object
// @returns {str[]} Reciever name and email
email.get.i.to:{[msg]
  toInfo:raze msg[`:get_all;<]each("to";"cc";"resent-to";"resent-cc");
  email.i.getAddr toInfo where not any(::;"")~/:\:toInfo
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the date information from an email
// @param msg {<} The email as an embedPy object
// @returns {timestamp} Date email was sent
email.get.i.date:{[msg]
  dates:string 6#email.i.parseDate msg[@;`date];
  "P"$"D"sv".:"sv'3 cut{$[1=count x;"0";""],x}each dates
  }
 
// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the subject information from an email
// @param msg {<} The email as an embedPy object
// @returns {str} Subject of the email
email.get.i.subject:{[msg]
  subject:msg[@;`subject];
  $[(::)~subject`;
    "";
    email.i.makeHdr[email.i.decodeHdr subject][`:__str__][]`
    ]
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the content type of an email
// @param msg {<} The email as an embedPy object
// @returns {str} Content type of an email 
email.get.i.contentType:{[msg]
  msg[`:get_content_type][]`
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Extract the payload information from an email
// @param msg {<} The email as an embedPy object
// @returns {dict;tab} Dictionary of `attachment`content or a table of payloads
//   Content is byte[] for binary data, char[] for text
email.get.i.payload:{[msg]
  if[msg[`:is_multipart][]`;:email.i.parseMbox1 each msg[`:get_payload][]`];
  // Raw bytes decoded from base64 encoding, wrapped embedPy
  raw:msg[`:get_payload;`decode pykw 1]; 
  rtf:"application/rtf"~(msg[`:get_content_type][]`);
  attachment:"attachment"~msg[`:get_content_disposition][]`;
  payload:`attachment`content!(0b;raw`);
  if[all(rtf;attachment);:payload];
  if[attachment;
    payload,`attachment`filename!(1b;email[`:get_filename][]`);
    ];
  content:email.get.i.contentType msg;
  if[not any content~/:("text/html";"text/plain";"message/rfc822");:payload];
  charset:msg[`:get_content_charset][]`;
  content:i.str[raw;$[(::)~charset;"us-ascii";charset];"ignore"]`;
  `attachment`content!(0b;content)
  }


// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Get meta information from an email 
// @params filepath {str} The path to where the email is stored
// @returns {dict} Meta information from the email
email.i.parseMail:{[filepath]
  email.i.parseMbox1 email.i.msgFromString[filepath]`.
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Get meta information from an email 
// @params filepath {str} The path to the mbox
// @returns {dict} Meta information from the email
email.i.parseMbox:{[filepath]
  mbox:email.i.mbox filepath;
  email.i.parseMbox1 each .p.list[<] mbox
  }

// @private
// @kind function
// @category nlpEmailUtility
// @fileoverview Get meta information from an email 
// @params mbox {<} Emails in mbox format
// @returns {dict} Meta information from the email
email.i.parseMbox1:{[mbox]
  msgInfo:`sender`to`date`subject`contentType`payload;
  msgInfo!email.get.i[msgInfo]@\:.p.wrap mbox
  }

// Python imports
email.i.bs:.p.import[`bs4]`:BeautifulSoup
email.i.getAddr:.p.import[`email.utils;`:getaddresses;<]
email.i.parseDate:.p.import[`email.utils;`:parsedate;<]
email.i.decodeHdr:.p.import[`email.header;`:decode_header]
email.i.makeHdr:.p.import[`email.header;`:make_header]
email.i.msgFromString:.p.import[`email]`:message_from_string
email.i.mbox:.p.import[`mailbox]`:mbox
