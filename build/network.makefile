## Qt Lib name.
qt_network_name = QtNetwork

## Libraries linked to the cpp part (is active only when  CPP_SHARED == true).
network_link_cpp += qtdcore_cpp $(qt_core_lib_name)

## Libraries linked to the d part (is active only when  CPP_SHARED == true)..
network_link_d += qtdcore

## Module specific cpp files.
network_cpp_files += 

## Module specific d files.
network_d_files += 

network_d_files += qt/network/ArrayOps2

## Classes.
## TODO: use list that generated by dgen.
network_classes = \
ArrayOps \
QAbstractNetworkCache \
QAbstractSocket \
QAuthenticator \
QFtp \
QHostAddress \
QHostInfo \
QHttpHeader \
QHttpRequestHeader \
QHttpResponseHeader \
QHttp \
QIPv6Address \
QLocalServer \
QLocalSocket \
QNetworkAccessManager \
QNetworkAddressEntry \
QNetworkCookieJar \
QNetworkCookie \
QNetworkInterface \
QNetworkProxy \
QNetworkProxyFactory \
QNetworkReply \
QNetworkRequest \
QSsl \
QSslCertificate \
QSslCipher \
QSslConfiguration \
QSslError \
QSslKey \
QSslSocket \
QTcpServer \
QTcpSocket \
QUdpSocket \
QUrlInfo