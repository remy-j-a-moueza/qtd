#include <QUrl>
#include <QObjectEntity.h>

class UrlHandler : public QObject, public Qtd_QObjectEntity
{
    Q_OBJECT

public:
    UrlHandler(void *d_ptr, QObject *parent = 0);

public slots:
    void handleUrl(const QUrl &url);
};
