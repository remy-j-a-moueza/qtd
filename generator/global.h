#ifndef GLOBAL_H
#define GLOBAL_H

#include <QString>

class Global
{
public:
    enum TargetPlatform
    {
        UnixTarget,
        Win32Target
    };

    TargetPlatform targetPlatform;
    bool cppShared;
    bool dPhobos;
    int dVersion;


    void setTargetPlatform(QString tp)
    {
        if (tp == "win32")
            targetPlatform = Win32Target;
        else if (tp == "unix")
            targetPlatform = UnixTarget;

        else if (tp.isEmpty()) {
#if WIN32
            targetPlatform = Win32Target;
#else
            targetPlatform = UnixTarget;
#endif
        }
        else
            qFatal("Target platform %s is not supported", qPrintable(tp));
    }

    Global();

};

extern Global global;

#endif // GLOBAL_H
