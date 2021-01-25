\d .nlp

// @kind function
// @category nlpClustering
// @fileoverview Clustering algorithms can be run on either documents, or on 
//   keyword dictionaries, which can be useful if you are clustering things 
//   other than documents, like words or sentences.
//   This function will, if the input is a list of documents, extract the 
//   keyword list
// @param docs {tab;dict[]} A list of documents, or a list of keyword 
//   dictionaries
// @returns {dict[]} Keyword dictionaries
cluster.i.asKeywords:{[docs]
  keyWords:$[-9=type docs[0]`keywords;docs;docs`keywords];
  i.fillEmptyDocs keyWords
  }

// @kind function
// @category nlpClustering
// @fileoverview Get the cohesiveness of a cluster as measured by the mean 
//   sum of squares error
// @param docs {dict[]} A document's keyword field
// @returns {float} The cohesion of the cluster
cluster.MSE:{[docs]
  n:count docs;
  if[(0=n)|0=sum count each docs,(::);:0n];
  if[1=n;:1f];
  centroid:i.takeTop[50]i.fastSum docs;
  docs:i.fillEmptyDocs docs;
  // Don't include the current document in the centroid, or for small clusters
  // it just reflects its similarity to itself
  dists:0^compareDocToCentroid[centroid]each docs;
  avg dists*dists
 }

// @kind function
// @category nlpClustering
// @fileoverview The bisecting k-means algorithm which uses k-means to 
//  repeatedly split the most cohesive clusters into two clusters
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param k {long} The number of clusters to return
// @param iters {long} The number of times to iterate the refining step
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.bisectingKMeans:{[docs;k;iters]
  docs:cluster.i.asKeywords docs;
  if[0=n:count docs;:()];
  (k-1)cluster.i.bisect[iters;docs]/enlist til n
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview The bisecting k-means algorithm which uses k-means to 
//  repeatedly split the most cohesive clusters into two clusters
// @param iters {long} The number of times to iterate the refining step
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param clusters {long} Cluster indices
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.i.bisect:{[iters;docs;clusters]
  idx:i.minIndex cluster.MSE each docs clusters;
  cluster:clusters idx;
  (clusters _ idx),cluster@/:cluster.kmeans[docs cluster;2;iters]
  }

// @kind function
// @category nlpClustering
// @fileoverview k-means clustering for documents
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param k {long} The number of clusters to return
// @param iters {long} The number of times to iterate the refining step
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.kmeans:{[docs;k;iters]
  docs:cluster.i.asKeywords docs;
  numDocs:count docs;
  iters cluster.i.kmeans[docs]/(k;0N)#neg[numDocs]?numDocs
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview k-means clustering for documents
// @param docs {dict[]} Keywords in documents
// @param clusters {long[]} Cluster indices
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.i.kmeans:{[docs;clusters]
  centroids:(i.takeTop[3]i.fastSum@)each docs clusters;
  value group i.maxIndex each centroids compareDocs\:/:docs
  }

// @kind function
// @category nlpClustering
// @fileoverview Given a list of centroids and a list of documents, match each
//   document to its nearest centroid
// @param centroids {dict[]} Centroids as keyword dictionaries
// @param docs {dict[]} A list of document feature vectors
// @returns {long[][]} Lists of document indices where each list is a cluster
//  N.B. These don't line up with the number of centroids passed in,
//  and the number of lists returned may not equal the number of centroids.
//  There can be documents which match no centroids (all of which will end up 
//  in the same group), and centroids with no matching documents.
cluster.groupByCentroids:{[centroids;docs]
  // If there are no centroids, everything is in one group
  if[not count centroids;:enlist til count docs];
  value group cluster.i.findNearestNeighbor[centroids]each docs
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview Find nearest neighbor of document
// @param centroids {dict[]} Centroids as keyword dictionaries
// @param docs {dict} Document feature vectors
// @returns {long[][]} Document indices 
cluster.i.findNearestNeighbor:{[centroids;doc]
  similarities:compareDocs[doc] each centroids;
  m:max similarities;
  $[m>0f;similarities?m;0n]
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview Merge any clusters with significant overlap into a single 
//   cluster
// @param clusters {any[][]} Cluster indices
// @returns {any[][]} Appropriate clusters merged together
cluster.i.mergeOverlappingClusters:{[clusters]
  counts:count each clusters;
  similar:cluster.i.similarClusters[clusters;counts]each til count clusters;
  // Merge any cluster that has at least one similar cluster
  // A boolean vector of which clusters will be getting merged
  merge:1<count each similar;
  // Filter out clusters of 1, and remove duplicates
  similarClusters:distinct desc each similar where merge;
  // Do the actual merging of the similar clusters
  newClusters:(distinct raze@)each clusters similarClusters;
  // Clusters not involved in any merge
  // This can't just be (not merge), as that only drops the larger cluster,
  // not the smaller one, in each merge
  untouchedClusters:(til count clusters)except raze similarClusters;
  clusters[untouchedClusters],newClusters
  }

// @private
// @kind function
// @category nlpClusteringUtility
// fileoverview Group together clusters that share over 50% of their elements
// @param clusters {any[][]} Cluster indices
// @param counts {long} Count of each cluster
// @param idx {long} Index of cluster
// @return {any[][]} Clusters grouped together
cluster.i.similarClusters:{[clusters;counts;idx]
  superset:counts=sum each clusters[idx]in/:clusters;
  similar:.5<=avg each clusters[idx]in/:clusters;
  notSmaller:(count clusters idx)>=count each clusters;
  where superset or(similar & notSmaller)
  }

// @kind function
// @category nlpClustering
// @fileoverview An extremely fast clustering algorithm for very large datasets
//  Produces small but cohesive clusters.
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param numOfClusters {long} The number of clusters desired, though fewer 
//   may be returned.
//   This must be fairly high to cover a substantial amount of the corpus, as 
//   clusters are small
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.radix:{[docs;n]
  docs:cluster.i.asKeywords docs;
  // Bin on keywords, taking the 3 most significant keywords from each document
  // and dropping those that occur less than 3 times  
  reduced:{distinct 4#key desc x}each docs; 
  // Remove any keywords that occur less than 5 times
  keywords:where (count each group raze reduced) >= 5;
  keywords:keywords except `;
  clusters:{[reduced;keyword]where keyword in/:reduced}[reduced]each keywords;
  // Score clusters based on the harmonic mean of their cohesion and log(size)
  cohesion:i.normalize cluster.MSE each docs clusters;
  size:i.normalize log count each clusters;
  score:i.harmonicMean each flip(cohesion;size);
  // Take the n*2 highest scoring clusters, as merging will remove some
  // but don't run it on everything, since merging is expensive.
  // This may lead to fewer clusters than expected if a lot of merging happens
  clusters:clusters sublist[2*n]idesc score;
  sublist[n]cluster.i.mergeOverlappingClusters/[clusters]
  }

// @kind function
// @category nlpClustering
// @fileoverview An extremely fast clustering algorithm for very large datasets.
//  Produces small but cohesive clusters.
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param numOfClusters {long} The number of clusters desired, though fewer may
//  be returned.
//  This must be fairly high to cover a substantial amount of the corpus, as 
//  clusters are small
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.fastRadix:{[docs;n]
  docs:cluster.i.asKeywords docs;
  // Group documents by their most significant term
  grouped:group i.maxIndex each docs;
  // Remove the entry for empty documents
  grouped:grouped _ `;
  // Remove all clusters containing only one element
  clusters:grouped where 1<count each grouped;
  // Score clusters based on the harmonic mean of their cohesion and log(size)
  cohesion:i.normalize cluster.MSE each docs clusters;
  size:i.normalize log count each clusters;
  score:i.harmonicMean each flip(cohesion;size);
  // Return the n highest scoring clusters
  clusters sublist[n]idesc score
  }

// @kind function
// @category nlpClustering
// @fileoverview Cluster a subcorpus using graph clustering
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param minimum {float} The minimum similarity that will be considered
// @param sample {bool} If this is true, a sample of sqrt(n) documents is used
// @returns {long[][]} The documents' indices, grouped into clusters
cluster.MCL:{[docs;minimum;sample]
  docs:cluster.i.asKeywords docs;
  idx:$[sample;(neg"i"$sqrt count docs)?count docs;til count docs];
  keywords:docs idx;
  n:til count keywords;
  similarities:i.matrixFromRaggedList i.compareDocToCorpus[keywords]each n;
  // Find all the clusters
  clusters:cluster.i.similarityMatrix similarities>=minimum;
  clustersOfOne:1=count each clusters;
  if[not sample;:clusters where not clustersOfOne];
  // Any cluster of 1 documents isn't a cluster, so throw it out
  outliers:raze clusters where clustersOfOne;
  // Only keep clusters where the count is greater than one
  clusters@:where 1<count each clusters;
  // Find the centroid of each cluster
  centroids:avg each keywords clusters;
  // Move each non-outlier to the nearest centroid
  nonOutliers:(til count docs)except idx outliers;
  nonOutliers cluster.groupByCentroids[centroids;docs nonOutliers]
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview Normalize the columns of a matrix so they sum to 1
// @param matrix {float[][]} Numeric matrix of values 
// @returns {float[][]} The normalized columns
cluster.i.columnNormalize:{[matrix]
  0f^matrix%\:sum matrix
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview Graph clustering that works on a similarity matrix
// @param matrix {bool[][]} NxN adjacency matrix
// @returns {long[][]} Lists of indices in the corpus where each row 
//   is a cluster
cluster.i.similarityMatrix:{[matrix]
  matrix:"f"$matrix;
  // Make the matrix stochastic and run MCL until stable
  normMatrix:cluster.i.columnNormalize matrix;
  attractors:cluster.i.MCL/[normMatrix];
  // Use output of MCL to get the clusters
  clusters:where each attractors>0;
  // Remove empty clusters and duplicates
  distinct clusters where 0<>count each clusters
  }

// @private
// @kind function
// @category nlpClusteringUtility
// @fileoverview SM Van Dongen's MCL clustering algorithm
// @param matrix {float[][]} NxN matrix
// @return {float[][]} MCL algorithm applied to matrix
cluster.i.MCL:{[matrix]
  // Expand matrix by raising to the nth power (currently set to 2)
  do[2-1;mat:{i.np[`:matmul;x;x]`}matrix];
  mat:cluster.i.columnNormalize mat*mat;
  @[;;:;0f] ./:flip(mat;where each(mat>0)&(mat<.00001))
  }

// @kind function
// @category nlpClustering
// @fileoverview A clustering algorithm that works like many summarizing 
//   algorithms, by finding the most representive elements, then subtracting 
//   them from the centroid, and iterating until the number of clusters has 
//   been reached
// @param docs {tab;dict[]} A list of documents, or document keywords
// @param numOfClusters {long} The number of clusters to return
// @returns {long[][]} The documents' indices grouped into clusters
cluster.summarize:{[docs;n]
  if[0=count docs;:()];
  docs:i.takeTop[10]each cluster.i.asKeywords docs;
  summary:i.fastSum[docs]%count docs;
  centroids:();
  do[n;
    // Find the document that summarizes the corpus best
    // and move that document to the centroid list
    centroids,:nearest:i.maxIndex docs[;i.maxIndex summary];
    summary-:docs nearest;
    summary:(where summary<0)_ summary
    ];
  cluster.groupByCentroids[docs centroids;docs]
  }
