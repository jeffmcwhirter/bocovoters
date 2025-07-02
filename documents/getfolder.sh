export ID="${1}"
curl  --output "${2}" \
      'https://documents.bouldercolorado.gov/WebLink/FolderListingService.aspx/GetFolderListing2' \
  --compressed \
  -X POST \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:139.0) Gecko/20100101 Firefox/139.0' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate, br, zstd' \
  -H 'Content-Type: application/json' \
  -H 'X-Lf-Suppress-Login-Redirect: 1' \
  -H 'Origin: https://documents.bouldercolorado.gov' \
  -H 'DNT: 1' \
  -H 'Connection: keep-alive' \
  -H 'Referer: https://documents.bouldercolorado.gov/WebLink/Browse.aspx?id=${ID}^&dbid=0^&repo=LF8PROD2' \
  -H 'Cookie: WebLinkSession=ztjbtm3qn4zi5awh0zcajvzw; lastSessionAccess=638869436949609975; AcceptsCookies=1; MachineTag=06939ccd-d62f-49c2-a3d4-8b2c66400d9a' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'Priority: u=0' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  --data-raw "{\"repoName\":\"LF8PROD2\",\"folderId\":${ID},\"getNewListing\":true,\"start\":0,\"end\":40,\"sortColumn\":\"\",\"sortAscending\":true}"

