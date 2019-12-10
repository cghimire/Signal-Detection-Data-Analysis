function findMuons(readFile)
strVals=readLBCF_File(readFile,0,0);
a= strVals(: ,1:8);
for ii=1:32
  results(ii,:)= sum(bitand(a,2^(ii-1))>0);
end
[channelNum, stretcherNum] =find(results >0);