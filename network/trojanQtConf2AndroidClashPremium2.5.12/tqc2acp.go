package main

/**
 * 将Trojan-Qt5-windows.1.1.6导出的gui-config.json，
 * 转换为Clash For Android(2.5.12 Premium版, 包名com.github.kr328.clash)可用的配置文件
 *
 * 使用：
 *		go run tqc2acp.go
 */

/**
执行过程：
golang读取gui-config.json文件，暂存到变量data。
设定变量proxies(字符串数组类型)。
获取 data下的名为config的数组，遍历之。
在遍历过程中，获取每个元素下的 server、server_port、password、remarks、verify_certificate属性（除了verify_certificate是boolean属性，其它的都是字符串属性）。
将server值塞进proxies数组。
用server、server_port、password、remarks、verify_certificate属性值拼接以下字符串（含换行符和空格，以分割线”=====“为界，但不要包含分割线”=====“）：
=====
  -
    name: remarks属性值
    type: trojan
    server: server属性值
    port: server_port属性值
    password: password属性值
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: verify_certificate属性值（填true或false）
=====


在以上循环结束后，遍历proxies变量，每次循环以以下字符串拼接（，以分割线”=====“为界，但不要包含分割线”=====“）：
=====
  - proxies数组元素的值
=====
Read gui-config.json file in Go and store it in the 'data' variable.
Define a variable 'proxies' (string array type).
Retrieve the 'config' array under the 'data' object and iterate through it.
During the iteration, extract the 'server', 'server_port', 'password', 'remarks', and 'verify_certificate' properties (except 'verify_certificate', which is a boolean property).
Add the 'server' value to the 'proxies' array.
Concatenate the following string using the extracted properties (including line breaks and spaces, with the separator "=====" but excluding the actual separator):
=====
  -
    name: remarks property value
    type: trojan
    server: server property value
    port: server_port property value
    password: password property value
    alpn:
      - h2
      - http/1.1
    skip-cert-verify: verify_certificate property value (true or false)
=====
After the loop ends, iterate through the 'proxies' variable and concatenate the following string for each element (with the separator "=====" but excluding the actual separator):
=====
  - value of the proxies array element
=====
*/

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os" // Import the os package for file operations
)

func main() {
	// Read gui-config.json file and store it in the 'data' variable.
	data, err := ioutil.ReadFile("gui-config.json")
	if err != nil {
		log.Fatal("Error reading gui-config.json:", err)
	}

	// Define a variable 'proxies' (string array type).
	var proxies []string

	// Unmarshal the JSON data into a map.
	var configData map[string]interface{}
	if err := json.Unmarshal(data, &configData); err != nil {
		log.Fatal("Error unmarshaling JSON:", err)
	}

	// Retrieve the 'config' array under the 'data' object and iterate through it.
	configArray, ok := configData["configs"].([]interface{})
	if !ok {
		log.Fatal("Invalid format: 'config' array not found.")
	}

	// Create or open the clash.txt file for writing
	file, err := os.Create("clash.txt")
	if err != nil {
		log.Fatal("Error creating clash.txt:", err)
	}
	defer file.Close() // Close the file when done

	os.Truncate("clash.txt", 0)
	fmt.Fprintf(file,
		`port: 7890
socks-port: 7891
allow-lan: false
mode: Rule
log-level: silent
external-controller: 127.0.0.1:9090
secret: ""
dns:
  enable: true
  ipv6: false
  nameserver:
    - 223.5.5.5
    - 180.76.76.76
    - 119.29.29.29
    - 117.50.11.11
    - 117.50.10.10
    - 114.114.114.114
    - https://dns.alidns.com/dns-query
    - https://doh.360.cn/dns-query
  fallback:
    - 8.8.8.8
    - tls://dns.rubyfish.cn:853
    - tls://1.0.0.1:853
    - tls://dns.google:853
    - https://dns.rubyfish.cn/dns-query
    - https://cloudflare-dns.com/dns-query
    - https://dns.google/dns-query
  fallback-filter:
    geoip: true
    ipcidr:
      - 240.0.0.0/4
      - 0.0.0.0/32
      - 127.0.0.1/32
    domain:
      - +.google.com
      - +.facebook.com
      - +.youtube.com
      - +.xn--ngstr-lra8j.com
      - +.google.cn
      - +.googleapis.cn
      - +.gvt1.com
proxies:
`)

	for _, configItem := range configArray {
		configItemMap, ok := configItem.(map[string]interface{})
		if !ok {
			log.Println("Invalid format: skipping config item.")
			continue
		}

		// Extract properties: 'server', 'server_port', 'password', 'remarks', and 'verify_certificate'.
		server, ok := configItemMap["server"].(string)
		if !ok {
			log.Println("Invalid format: skipping config item without 'server'.")
			continue
		}
		serverPort, ok := configItemMap["server_port"].(float64)
		if !ok {
			log.Println("Invalid format: skipping config item without 'server_port'.")
			continue
		}
		password, ok := configItemMap["password"].(string)
		if !ok {
			log.Println("Invalid format: skipping config item without 'password'.")
			continue
		}
		remarks, ok := configItemMap["remarks"].(string)
		if !ok {
			log.Println("Invalid format: skipping config item without 'remarks'.")
			continue
		}
		verifyCert, ok := configItemMap["verify_certificate"].(bool)
		if !ok {
			log.Println("Invalid format: skipping config item without 'verify_certificate'.")
			continue
		}
		skipVerifyCert := !verifyCert

		// Write the required string to the file
		fmt.Fprintf(file, "  -\n")
		fmt.Fprintf(file, "    name: %s\n", remarks)
		fmt.Fprintf(file, "    type: trojan\n")
		fmt.Fprintf(file, "    server: %s\n", server)
		fmt.Fprintf(file, "    port: %.0f\n", serverPort)
		fmt.Fprintf(file, "    password: %s\n", password)
		fmt.Fprintf(file, "    alpn:\n")
		fmt.Fprintf(file, "      - h2\n")
		fmt.Fprintf(file, "      - http/1.1\n")
		fmt.Fprintf(file, "    skip-cert-verify: %v\n", skipVerifyCert)

		// Add the 'server' value to the 'proxies' array.
		proxies = append(proxies, remarks)
	}

	fmt.Fprintf(file,
		`proxy-groups:
  - 
    name: Auto
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    proxies:
`)

	// Iterate through the 'proxies' variable and write to the file
	for _, proxy := range proxies {
		fmt.Fprintf(file, "      - %s\n", proxy)
	}

	fmt.Fprintf(file,
		`  - 
    name: Proxy
    type: select
    proxies:
      - Auto
`)

	// Iterate through the 'proxies' variable and write to the file
	for _, proxy := range proxies {
		fmt.Fprintf(file, "      - %s\n", proxy)
	}

	fmt.Fprintf(file,
		`rules:
- DOMAIN-SUFFIX,ghcr.io,Proxy
- DOMAIN-SUFFIX,googleapis.cn,Proxy
- DOMAIN-KEYWORD,googleapis.cn,Proxy
- DOMAIN,safebrowsing.urlsec.qq.com,DIRECT
- DOMAIN,safebrowsing.googleapis.com,DIRECT
- DOMAIN,ocsp.apple.com,Proxy
- DOMAIN-SUFFIX,digicert.com,Proxy
- DOMAIN-SUFFIX,entrust.net,Proxy
- DOMAIN,ocsp.verisign.net,Proxy
- DOMAIN-SUFFIX,apps.apple.com,Proxy
- DOMAIN,itunes.apple.com,Proxy
- DOMAIN-SUFFIX,blobstore.apple.com,Proxy
- DOMAIN-SUFFIX,music.apple.com,DIRECT
- DOMAIN-SUFFIX,mzstatic.com,DIRECT
- DOMAIN-SUFFIX,itunes.apple.com,DIRECT
- DOMAIN-SUFFIX,icloud.com,DIRECT
- DOMAIN-SUFFIX,icloud-content.com,DIRECT
- DOMAIN-SUFFIX,me.com,DIRECT
- DOMAIN-SUFFIX,mzstatic.com,DIRECT
- DOMAIN-SUFFIX,akadns.net,DIRECT
- DOMAIN-SUFFIX,aaplimg.com,DIRECT
- DOMAIN-SUFFIX,cdn-apple.com,DIRECT
- DOMAIN-SUFFIX,apple.com,DIRECT
- DOMAIN-SUFFIX,apple-cloudkit.com,DIRECT
- DOMAIN,e.crashlytics.com,REJECT
- DOMAIN-SUFFIX,cn,DIRECT
- DOMAIN-KEYWORD,-cn,DIRECT
- DOMAIN-SUFFIX,126.com,DIRECT
- DOMAIN-SUFFIX,126.net,DIRECT
- DOMAIN-SUFFIX,127.net,DIRECT
- DOMAIN-SUFFIX,163.com,DIRECT
- DOMAIN-SUFFIX,360buyimg.com,DIRECT
- DOMAIN-SUFFIX,36kr.com,DIRECT
- DOMAIN-SUFFIX,acfun.tv,DIRECT
- DOMAIN-SUFFIX,air-matters.com,DIRECT
- DOMAIN-SUFFIX,aixifan.com,DIRECT
- DOMAIN-SUFFIX,akamaized.net,DIRECT
- DOMAIN-KEYWORD,alicdn,DIRECT
- DOMAIN-KEYWORD,alipay,DIRECT
- DOMAIN-KEYWORD,taobao,DIRECT
- DOMAIN-SUFFIX,amap.com,DIRECT
- DOMAIN-SUFFIX,autonavi.com,DIRECT
- DOMAIN-KEYWORD,baidu,DIRECT
- DOMAIN-SUFFIX,bdimg.com,DIRECT
- DOMAIN-SUFFIX,bdstatic.com,DIRECT
- DOMAIN-SUFFIX,bilibili.com,DIRECT
- DOMAIN-SUFFIX,bilivideo.com,DIRECT
- DOMAIN-SUFFIX,caiyunapp.com,DIRECT
- DOMAIN-SUFFIX,clouddn.com,DIRECT
- DOMAIN-SUFFIX,cnbeta.com,DIRECT
- DOMAIN-SUFFIX,cnbetacdn.com,DIRECT
- DOMAIN-SUFFIX,cootekservice.com,DIRECT
- DOMAIN-SUFFIX,csdn.net,DIRECT
- DOMAIN-SUFFIX,ctrip.com,DIRECT
- DOMAIN-SUFFIX,dgtle.com,DIRECT
- DOMAIN-SUFFIX,dianping.com,DIRECT
- DOMAIN-SUFFIX,douban.com,DIRECT
- DOMAIN-SUFFIX,doubanio.com,DIRECT
- DOMAIN-SUFFIX,duokan.com,DIRECT
- DOMAIN-SUFFIX,easou.com,DIRECT
- DOMAIN-SUFFIX,ele.me,DIRECT
- DOMAIN-SUFFIX,feng.com,DIRECT
- DOMAIN-SUFFIX,fir.im,DIRECT
- DOMAIN-SUFFIX,frdic.com,DIRECT
- DOMAIN-SUFFIX,g-cores.com,DIRECT
- DOMAIN-SUFFIX,godic.net,DIRECT
- DOMAIN-SUFFIX,gtimg.com,DIRECT
- DOMAIN,cdn.hockeyapp.net,DIRECT
- DOMAIN-SUFFIX,hongxiu.com,DIRECT
- DOMAIN-SUFFIX,hxcdn.net,DIRECT
- DOMAIN-SUFFIX,iciba.com,DIRECT
- DOMAIN-SUFFIX,ifeng.com,DIRECT
- DOMAIN-SUFFIX,ifengimg.com,DIRECT
- DOMAIN-SUFFIX,ipip.net,DIRECT
- DOMAIN-SUFFIX,iqiyi.com,DIRECT
- DOMAIN-SUFFIX,jd.com,DIRECT
- DOMAIN-SUFFIX,jianshu.com,DIRECT
- DOMAIN-SUFFIX,knewone.com,DIRECT
- DOMAIN-SUFFIX,le.com,DIRECT
- DOMAIN-SUFFIX,lecloud.com,DIRECT
- DOMAIN-SUFFIX,lemicp.com,DIRECT
- DOMAIN-SUFFIX,licdn.com,DIRECT
- DOMAIN-SUFFIX,linkedin.com,Proxy
- DOMAIN-SUFFIX,luoo.net,DIRECT
- DOMAIN-SUFFIX,meituan.com,DIRECT
- DOMAIN-SUFFIX,meituan.net,DIRECT
- DOMAIN-SUFFIX,mi.com,DIRECT
- DOMAIN-SUFFIX,miaopai.com,DIRECT
- DOMAIN-SUFFIX,microsoft.com,DIRECT
- DOMAIN-SUFFIX,microsoftonline.com,DIRECT
- DOMAIN-SUFFIX,miui.com,DIRECT
- DOMAIN-SUFFIX,miwifi.com,DIRECT
- DOMAIN-SUFFIX,mob.com,DIRECT
- DOMAIN-SUFFIX,netease.com,DIRECT
- DOMAIN-SUFFIX,office.com,DIRECT
- DOMAIN-SUFFIX,office365.com,DIRECT
- DOMAIN-KEYWORD,officecdn,DIRECT
- DOMAIN-SUFFIX,oschina.net,DIRECT
- DOMAIN-SUFFIX,ppsimg.com,DIRECT
- DOMAIN-SUFFIX,pstatp.com,DIRECT
- DOMAIN-SUFFIX,qcloud.com,DIRECT
- DOMAIN-SUFFIX,qdaily.com,DIRECT
- DOMAIN-SUFFIX,qdmm.com,DIRECT
- DOMAIN-SUFFIX,qhimg.com,DIRECT
- DOMAIN-SUFFIX,qhres.com,DIRECT
- DOMAIN-SUFFIX,qidian.com,DIRECT
- DOMAIN-SUFFIX,qihucdn.com,DIRECT
- DOMAIN-SUFFIX,qiniu.com,DIRECT
- DOMAIN-SUFFIX,qiniucdn.com,DIRECT
- DOMAIN-SUFFIX,qiyipic.com,DIRECT
- DOMAIN-SUFFIX,qq.com,DIRECT
- DOMAIN-SUFFIX,qqurl.com,DIRECT
- DOMAIN-SUFFIX,rarbg.to,DIRECT
- DOMAIN-SUFFIX,ruguoapp.com,DIRECT
- DOMAIN-SUFFIX,segmentfault.com,DIRECT
- DOMAIN-SUFFIX,sinaapp.com,DIRECT
- DOMAIN-SUFFIX,smzdm.com,DIRECT
- DOMAIN-SUFFIX,snapdrop.net,DIRECT
- DOMAIN-SUFFIX,sogou.com,DIRECT
- DOMAIN-SUFFIX,sogoucdn.com,DIRECT
- DOMAIN-SUFFIX,sohu.com,DIRECT
- DOMAIN-SUFFIX,soku.com,DIRECT
- DOMAIN-SUFFIX,speedtest.net,DIRECT
- DOMAIN-SUFFIX,sspai.com,DIRECT
- DOMAIN-SUFFIX,suning.com,DIRECT
- DOMAIN-SUFFIX,taobao.com,DIRECT
- DOMAIN-SUFFIX,tencent.com,DIRECT
- DOMAIN-SUFFIX,tenpay.com,DIRECT
- DOMAIN-SUFFIX,tianyancha.com,DIRECT
- DOMAIN-SUFFIX,tmall.com,DIRECT
- DOMAIN-SUFFIX,tudou.com,DIRECT
- DOMAIN-SUFFIX,umetrip.com,DIRECT
- DOMAIN-SUFFIX,upaiyun.com,DIRECT
- DOMAIN-SUFFIX,upyun.com,DIRECT
- DOMAIN-SUFFIX,veryzhun.com,DIRECT
- DOMAIN-SUFFIX,weather.com,DIRECT
- DOMAIN-SUFFIX,weibo.com,DIRECT
- DOMAIN-SUFFIX,xiami.com,DIRECT
- DOMAIN-SUFFIX,xiami.net,DIRECT
- DOMAIN-SUFFIX,xiaomicp.com,DIRECT
- DOMAIN-SUFFIX,ximalaya.com,DIRECT
- DOMAIN-SUFFIX,xmcdn.com,DIRECT
- DOMAIN-SUFFIX,xunlei.com,DIRECT
- DOMAIN-SUFFIX,yhd.com,DIRECT
- DOMAIN-SUFFIX,yihaodianimg.com,DIRECT
- DOMAIN-SUFFIX,yinxiang.com,DIRECT
- DOMAIN-SUFFIX,ykimg.com,DIRECT
- DOMAIN-SUFFIX,youdao.com,DIRECT
- DOMAIN-SUFFIX,youku.com,DIRECT
- DOMAIN-SUFFIX,zealer.com,DIRECT
- DOMAIN-SUFFIX,zhihu.com,DIRECT
- DOMAIN-SUFFIX,zhimg.com,DIRECT
- DOMAIN-SUFFIX,zimuzu.tv,DIRECT
- DOMAIN-SUFFIX,zoho.com,DIRECT
- DOMAIN-KEYWORD,amazon,Proxy
- DOMAIN-KEYWORD,google,Proxy
- DOMAIN-KEYWORD,gmail,Proxy
- DOMAIN-KEYWORD,youtube,Proxy
- DOMAIN-KEYWORD,facebook,Proxy
- DOMAIN-SUFFIX,fb.me,Proxy
- DOMAIN-SUFFIX,fbcdn.net,Proxy
- DOMAIN-KEYWORD,twitter,Proxy
- DOMAIN-KEYWORD,instagram,Proxy
- DOMAIN-KEYWORD,dropbox,Proxy
- DOMAIN-SUFFIX,twimg.com,Proxy
- DOMAIN-KEYWORD,blogspot,Proxy
- DOMAIN-SUFFIX,youtu.be,Proxy
- DOMAIN-KEYWORD,whatsapp,Proxy
- DOMAIN-KEYWORD,admarvel,REJECT
- DOMAIN-KEYWORD,admaster,REJECT
- DOMAIN-KEYWORD,adsage,REJECT
- DOMAIN-KEYWORD,adsmogo,REJECT
- DOMAIN-KEYWORD,adsrvmedia,REJECT
- DOMAIN-KEYWORD,adwords,REJECT
- DOMAIN-KEYWORD,adservice,REJECT
- DOMAIN-KEYWORD,domob,REJECT
- DOMAIN-KEYWORD,duomeng,REJECT
- DOMAIN-KEYWORD,dwtrack,REJECT
- DOMAIN-KEYWORD,guanggao,REJECT
- DOMAIN-KEYWORD,lianmeng,REJECT
- DOMAIN-SUFFIX,mmstat.com,REJECT
- DOMAIN-KEYWORD,omgmta,REJECT
- DOMAIN-KEYWORD,openx,REJECT
- DOMAIN-KEYWORD,partnerad,REJECT
- DOMAIN-KEYWORD,pingfore,REJECT
- DOMAIN-KEYWORD,supersonicads,REJECT
- DOMAIN-KEYWORD,uedas,REJECT
- DOMAIN-KEYWORD,umeng,REJECT
- DOMAIN-KEYWORD,usage,REJECT
- DOMAIN-KEYWORD,wlmonitor,REJECT
- DOMAIN-SUFFIX,webogram,REJECT
- DOMAIN-KEYWORD,zjtoolbar,REJECT
- DOMAIN-SUFFIX,9to5mac.com,Proxy
- DOMAIN-SUFFIX,abpchina.org,Proxy
- DOMAIN-SUFFIX,adblockplus.org,Proxy
- DOMAIN-SUFFIX,adobe.com,Proxy
- DOMAIN-SUFFIX,alfredapp.com,Proxy
- DOMAIN-SUFFIX,amplitude.com,Proxy
- DOMAIN-SUFFIX,ampproject.org,Proxy
- DOMAIN-SUFFIX,android.com,Proxy
- DOMAIN-SUFFIX,angularjs.org,Proxy
- DOMAIN-SUFFIX,aolcdn.com,Proxy
- DOMAIN-SUFFIX,apkpure.com,Proxy
- DOMAIN-SUFFIX,appledaily.com,Proxy
- DOMAIN-SUFFIX,appshopper.com,Proxy
- DOMAIN-SUFFIX,appspot.com,Proxy
- DOMAIN-SUFFIX,arcgis.com,Proxy
- DOMAIN-SUFFIX,archive.org,Proxy
- DOMAIN-SUFFIX,armorgames.com,Proxy
- DOMAIN-SUFFIX,aspnetcdn.com,Proxy
- DOMAIN-SUFFIX,att.com,Proxy
- DOMAIN-SUFFIX,awsstatic.com,Proxy
- DOMAIN-SUFFIX,azureedge.net,Proxy
- DOMAIN-SUFFIX,azurewebsites.net,Proxy
- DOMAIN-SUFFIX,bing.com,Proxy
- DOMAIN-SUFFIX,bintray.com,Proxy
- DOMAIN-SUFFIX,bit.com,Proxy
- DOMAIN-SUFFIX,bit.ly,Proxy
- DOMAIN-SUFFIX,bitbucket.org,Proxy
- DOMAIN-SUFFIX,bjango.com,Proxy
- DOMAIN-SUFFIX,bkrtx.com,Proxy
- DOMAIN-SUFFIX,blog.com,Proxy
- DOMAIN-SUFFIX,blogcdn.com,Proxy
- DOMAIN-SUFFIX,blogger.com,Proxy
- DOMAIN-SUFFIX,blogsmithmedia.com,Proxy
- DOMAIN-SUFFIX,blogspot.com,Proxy
- DOMAIN-SUFFIX,blogspot.hk,Proxy
- DOMAIN-SUFFIX,bloomberg.com,Proxy
- DOMAIN-SUFFIX,box.com,Proxy
- DOMAIN-SUFFIX,box.net,Proxy
- DOMAIN-SUFFIX,cachefly.net,Proxy
- DOMAIN-SUFFIX,chromium.org,Proxy
- DOMAIN-SUFFIX,cl.ly,Proxy
- DOMAIN-SUFFIX,cloudflare.com,Proxy
- DOMAIN-SUFFIX,cloudfront.net,Proxy
- DOMAIN-SUFFIX,cloudmagic.com,Proxy
- DOMAIN-SUFFIX,cmail19.com,Proxy
- DOMAIN-SUFFIX,cnet.com,Proxy
- DOMAIN-SUFFIX,cocoapods.org,Proxy
- DOMAIN-SUFFIX,comodoca.com,Proxy
- DOMAIN-SUFFIX,crashlytics.com,Proxy
- DOMAIN-SUFFIX,culturedcode.com,Proxy
- DOMAIN-SUFFIX,d.pr,Proxy
- DOMAIN-SUFFIX,danilo.to,Proxy
- DOMAIN-SUFFIX,dayone.me,Proxy
- DOMAIN-SUFFIX,db.tt,Proxy
- DOMAIN-SUFFIX,deskconnect.com,Proxy
- DOMAIN-SUFFIX,disq.us,Proxy
- DOMAIN-SUFFIX,disqus.com,Proxy
- DOMAIN-SUFFIX,disquscdn.com,Proxy
- DOMAIN-SUFFIX,dnsimple.com,Proxy
- DOMAIN-SUFFIX,docker.com,Proxy
- DOMAIN-SUFFIX,dribbble.com,Proxy
- DOMAIN-SUFFIX,droplr.com,Proxy
- DOMAIN-SUFFIX,duckduckgo.com,Proxy
- DOMAIN-SUFFIX,dueapp.com,Proxy
- DOMAIN-SUFFIX,dytt8.net,Proxy
- DOMAIN-SUFFIX,edgecastcdn.net,Proxy
- DOMAIN-SUFFIX,edgekey.net,Proxy
- DOMAIN-SUFFIX,edgesuite.net,Proxy
- DOMAIN-SUFFIX,engadget.com,Proxy
- DOMAIN-SUFFIX,entrust.net,Proxy
- DOMAIN-SUFFIX,eurekavpt.com,Proxy
- DOMAIN-SUFFIX,evernote.com,Proxy
- DOMAIN-SUFFIX,fabric.io,Proxy
- DOMAIN-SUFFIX,fast.com,Proxy
- DOMAIN-SUFFIX,fastly.net,Proxy
- DOMAIN-SUFFIX,fc2.com,Proxy
- DOMAIN-SUFFIX,feedburner.com,Proxy
- DOMAIN-SUFFIX,feedly.com,Proxy
- DOMAIN-SUFFIX,feedsportal.com,Proxy
- DOMAIN-SUFFIX,fiftythree.com,Proxy
- DOMAIN-SUFFIX,firebaseio.com,Proxy
- DOMAIN-SUFFIX,flexibits.com,Proxy
- DOMAIN-SUFFIX,flickr.com,Proxy
- DOMAIN-SUFFIX,flipboard.com,Proxy
- DOMAIN-SUFFIX,g.co,Proxy
- DOMAIN-SUFFIX,gabia.net,Proxy
- DOMAIN-SUFFIX,geni.us,Proxy
- DOMAIN-SUFFIX,gfx.ms,Proxy
- DOMAIN-SUFFIX,ggpht.com,Proxy
- DOMAIN-SUFFIX,ghostnoteapp.com,Proxy
- DOMAIN-SUFFIX,git.io,Proxy
- DOMAIN-KEYWORD,github,Proxy
- DOMAIN-SUFFIX,globalsign.com,Proxy
- DOMAIN-SUFFIX,gmodules.com,Proxy
- DOMAIN-SUFFIX,godaddy.com,Proxy
- DOMAIN-SUFFIX,golang.org,Proxy
- DOMAIN-SUFFIX,gongm.in,Proxy
- DOMAIN-SUFFIX,goo.gl,Proxy
- DOMAIN-SUFFIX,goodreaders.com,Proxy
- DOMAIN-SUFFIX,goodreads.com,Proxy
- DOMAIN-SUFFIX,gravatar.com,Proxy
- DOMAIN-SUFFIX,gstatic.com,Proxy
- DOMAIN-SUFFIX,gvt0.com,Proxy
- DOMAIN-SUFFIX,hockeyapp.net,Proxy
- DOMAIN-SUFFIX,hotmail.com,Proxy
- DOMAIN-SUFFIX,icons8.com,Proxy
- DOMAIN-SUFFIX,ifixit.com,Proxy
- DOMAIN-SUFFIX,ift.tt,Proxy
- DOMAIN-SUFFIX,ifttt.com,Proxy
- DOMAIN-SUFFIX,iherb.com,Proxy
- DOMAIN-SUFFIX,imageshack.us,Proxy
- DOMAIN-SUFFIX,img.ly,Proxy
- DOMAIN-SUFFIX,imgur.com,Proxy
- DOMAIN-SUFFIX,imore.com,Proxy
- DOMAIN-SUFFIX,instapaper.com,Proxy
- DOMAIN-SUFFIX,ipn.li,Proxy
- DOMAIN-SUFFIX,is.gd,Proxy
- DOMAIN-SUFFIX,issuu.com,Proxy
- DOMAIN-SUFFIX,itgonglun.com,Proxy
- DOMAIN-SUFFIX,itun.es,Proxy
- DOMAIN-SUFFIX,ixquick.com,Proxy
- DOMAIN-SUFFIX,j.mp,Proxy
- DOMAIN-SUFFIX,js.revsci.net,Proxy
- DOMAIN-SUFFIX,jshint.com,Proxy
- DOMAIN-SUFFIX,jtvnw.net,Proxy
- DOMAIN-SUFFIX,justgetflux.com,Proxy
- DOMAIN-SUFFIX,kat.cr,Proxy
- DOMAIN-SUFFIX,klip.me,Proxy
- DOMAIN-SUFFIX,libsyn.com,Proxy
- DOMAIN-SUFFIX,linode.com,Proxy
- DOMAIN-SUFFIX,lithium.com,Proxy
- DOMAIN-SUFFIX,littlehj.com,Proxy
- DOMAIN-SUFFIX,live.com,Proxy
- DOMAIN-SUFFIX,live.net,Proxy
- DOMAIN-SUFFIX,livefilestore.com,Proxy
- DOMAIN-SUFFIX,llnwd.net,Proxy
- DOMAIN-SUFFIX,macid.co,Proxy
- DOMAIN-SUFFIX,macromedia.com,Proxy
- DOMAIN-SUFFIX,macrumors.com,Proxy
- DOMAIN-SUFFIX,mashable.com,Proxy
- DOMAIN-SUFFIX,mathjax.org,Proxy
- DOMAIN-SUFFIX,medium.com,Proxy
- DOMAIN-SUFFIX,mega.co.nz,Proxy
- DOMAIN-SUFFIX,mega.nz,Proxy
- DOMAIN-SUFFIX,megaupload.com,Proxy
- DOMAIN-SUFFIX,microsofttranslator.com,Proxy
- DOMAIN-SUFFIX,mindnode.com,Proxy
- DOMAIN-SUFFIX,mobile01.com,Proxy
- DOMAIN-SUFFIX,modmyi.com,Proxy
- DOMAIN-SUFFIX,msedge.net,Proxy
- DOMAIN-SUFFIX,myfontastic.com,Proxy
- DOMAIN-SUFFIX,name.com,Proxy
- DOMAIN-SUFFIX,nextmedia.com,Proxy
- DOMAIN-SUFFIX,nsstatic.net,Proxy
- DOMAIN-SUFFIX,nssurge.com,Proxy
- DOMAIN-SUFFIX,nyt.com,Proxy
- DOMAIN-SUFFIX,nytimes.com,Proxy
- DOMAIN-SUFFIX,omnigroup.com,Proxy
- DOMAIN-SUFFIX,onedrive.com,Proxy
- DOMAIN-SUFFIX,onenote.com,Proxy
- DOMAIN-SUFFIX,ooyala.com,Proxy
- DOMAIN-SUFFIX,openvpn.net,Proxy
- DOMAIN-SUFFIX,openwrt.org,Proxy
- DOMAIN-SUFFIX,orkut.com,Proxy
- DOMAIN-SUFFIX,osxdaily.com,Proxy
- DOMAIN-SUFFIX,outlook.com,Proxy
- DOMAIN-SUFFIX,ow.ly,Proxy
- DOMAIN-SUFFIX,paddleapi.com,Proxy
- DOMAIN-SUFFIX,parallels.com,Proxy
- DOMAIN-SUFFIX,parse.com,Proxy
- DOMAIN-SUFFIX,pdfexpert.com,Proxy
- DOMAIN-SUFFIX,periscope.tv,Proxy
- DOMAIN-SUFFIX,pinboard.in,Proxy
- DOMAIN-SUFFIX,pinterest.com,Proxy
- DOMAIN-SUFFIX,pixelmator.com,Proxy
- DOMAIN-SUFFIX,pixiv.net,Proxy
- DOMAIN-SUFFIX,playpcesor.com,Proxy
- DOMAIN-SUFFIX,playstation.com,Proxy
- DOMAIN-SUFFIX,playstation.com.hk,Proxy
- DOMAIN-SUFFIX,playstation.net,Proxy
- DOMAIN-SUFFIX,playstationnetwork.com,Proxy
- DOMAIN-SUFFIX,pushwoosh.com,Proxy
- DOMAIN-SUFFIX,rime.im,Proxy
- DOMAIN-SUFFIX,servebom.com,Proxy
- DOMAIN-SUFFIX,sfx.ms,Proxy
- DOMAIN-SUFFIX,shadowsocks.org,Proxy
- DOMAIN-SUFFIX,sharethis.com,Proxy
- DOMAIN-SUFFIX,shazam.com,Proxy
- DOMAIN-SUFFIX,skype.com,Proxy
- DOMAIN-SUFFIX,smartdnsProxy.com,Proxy
- DOMAIN-SUFFIX,smartmailcloud.com,Proxy
- DOMAIN-SUFFIX,sndcdn.com,Proxy
- DOMAIN-SUFFIX,sony.com,Proxy
- DOMAIN-SUFFIX,soundcloud.com,Proxy
- DOMAIN-SUFFIX,sourceforge.net,Proxy
- DOMAIN-SUFFIX,spotify.com,Proxy
- DOMAIN-SUFFIX,squarespace.com,Proxy
- DOMAIN-SUFFIX,sstatic.net,Proxy
- DOMAIN-SUFFIX,st.luluku.pw,Proxy
- DOMAIN-SUFFIX,stackoverflow.com,Proxy
- DOMAIN-SUFFIX,startpage.com,Proxy
- DOMAIN-SUFFIX,staticflickr.com,Proxy
- DOMAIN-SUFFIX,steamcommunity.com,Proxy
- DOMAIN-SUFFIX,symauth.com,Proxy
- DOMAIN-SUFFIX,symcb.com,Proxy
- DOMAIN-SUFFIX,symcd.com,Proxy
- DOMAIN-SUFFIX,tapbots.com,Proxy
- DOMAIN-SUFFIX,tapbots.net,Proxy
- DOMAIN-SUFFIX,tdesktop.com,Proxy
- DOMAIN-SUFFIX,techcrunch.com,Proxy
- DOMAIN-SUFFIX,techsmith.com,Proxy
- DOMAIN-SUFFIX,thepiratebay.org,Proxy
- DOMAIN-SUFFIX,theverge.com,Proxy
- DOMAIN-SUFFIX,time.com,Proxy
- DOMAIN-SUFFIX,timeinc.net,Proxy
- DOMAIN-SUFFIX,tiny.cc,Proxy
- DOMAIN-SUFFIX,tinypic.com,Proxy
- DOMAIN-SUFFIX,tmblr.co,Proxy
- DOMAIN-SUFFIX,todoist.com,Proxy
- DOMAIN-SUFFIX,trello.com,Proxy
- DOMAIN-SUFFIX,trustasiassl.com,Proxy
- DOMAIN-SUFFIX,tumblr.co,Proxy
- DOMAIN-SUFFIX,tumblr.com,Proxy
- DOMAIN-SUFFIX,tweetdeck.com,Proxy
- DOMAIN-SUFFIX,tweetmarker.net,Proxy
- DOMAIN-SUFFIX,twitch.tv,Proxy
- DOMAIN-SUFFIX,txmblr.com,Proxy
- DOMAIN-SUFFIX,typekit.net,Proxy
- DOMAIN-SUFFIX,ubertags.com,Proxy
- DOMAIN-SUFFIX,ublock.org,Proxy
- DOMAIN-SUFFIX,ubnt.com,Proxy
- DOMAIN-SUFFIX,ulyssesapp.com,Proxy
- DOMAIN-SUFFIX,urchin.com,Proxy
- DOMAIN-SUFFIX,usertrust.com,Proxy
- DOMAIN-SUFFIX,v.gd,Proxy
- DOMAIN-SUFFIX,v2ex.com,Proxy
- DOMAIN-SUFFIX,vimeo.com,Proxy
- DOMAIN-SUFFIX,vimeocdn.com,Proxy
- DOMAIN-SUFFIX,vine.co,Proxy
- DOMAIN-SUFFIX,vivaldi.com,Proxy
- DOMAIN-SUFFIX,vox-cdn.com,Proxy
- DOMAIN-SUFFIX,vsco.co,Proxy
- DOMAIN-SUFFIX,vultr.com,Proxy
- DOMAIN-SUFFIX,w.org,Proxy
- DOMAIN-SUFFIX,w3schools.com,Proxy
- DOMAIN-SUFFIX,webtype.com,Proxy
- DOMAIN-SUFFIX,wikiwand.com,Proxy
- DOMAIN-SUFFIX,wikileaks.org,Proxy
- DOMAIN-SUFFIX,wikimedia.org,Proxy
- DOMAIN-SUFFIX,wikipedia.com,Proxy
- DOMAIN-SUFFIX,wikipedia.org,Proxy
- DOMAIN-SUFFIX,windows.com,Proxy
- DOMAIN-SUFFIX,windows.net,Proxy
- DOMAIN-SUFFIX,wire.com,Proxy
- DOMAIN-SUFFIX,wordpress.com,Proxy
- DOMAIN-SUFFIX,workflowy.com,Proxy
- DOMAIN-SUFFIX,wp.com,Proxy
- DOMAIN-SUFFIX,wsj.com,Proxy
- DOMAIN-SUFFIX,wsj.net,Proxy
- DOMAIN-SUFFIX,xda-developers.com,Proxy
- DOMAIN-SUFFIX,xeeno.com,Proxy
- DOMAIN-SUFFIX,xiti.com,Proxy
- DOMAIN-SUFFIX,yahoo.com,Proxy
- DOMAIN-SUFFIX,yimg.com,Proxy
- DOMAIN-SUFFIX,ying.com,Proxy
- DOMAIN-SUFFIX,yoyo.org,Proxy
- DOMAIN-SUFFIX,ytimg.com,Proxy
- DOMAIN-SUFFIX,telegra.ph,Proxy
- DOMAIN-SUFFIX,telegram.org,Proxy
- IP-CIDR,91.108.4.0/22,Proxy,no-resolve
- IP-CIDR,91.108.8.0/22,Proxy,no-resolve
- IP-CIDR,91.108.12.0/22,Proxy,no-resolve
- IP-CIDR,91.108.16.0/22,Proxy,no-resolve
- IP-CIDR,91.108.56.0/22,Proxy,no-resolve
- IP-CIDR,149.154.160.0/22,Proxy,no-resolve
- IP-CIDR,149.154.164.0/22,Proxy,no-resolve
- IP-CIDR,149.154.168.0/22,Proxy,no-resolve
- IP-CIDR,149.154.172.0/22,Proxy,no-resolve
- DOMAIN-SUFFIX,local,DIRECT
- IP-CIDR,127.0.0.0/8,DIRECT
- IP-CIDR,172.16.0.0/12,DIRECT
- IP-CIDR,192.168.0.0/16,DIRECT
- IP-CIDR,10.0.0.0/8,DIRECT
- IP-CIDR,17.0.0.0/8,DIRECT
- IP-CIDR,100.64.0.0/10,DIRECT
- GEOIP,CN,DIRECT
- MATCH,Proxy
`)

}