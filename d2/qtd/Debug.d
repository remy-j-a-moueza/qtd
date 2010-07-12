module qtd.Debug;

version (QtdUnittest)
    debug = UseQtdDebug;
else debug (QtdDebug)
    debug = UseQtdDebug;

debug (UseQtdDebug)
{
    import
        std.string,
        qtd.QtdObject;
}

string debugHandler(string handler, string[] args...)
{
    debug (UseQtdDebug)
    {
        string result = "qtdDebug." ~ handler ~ "(";
        foreach (i, arg; args)
        {
            if (i)
                result ~= ", ";
            result ~= arg;
        }
        return result ~ ");";
    }
    else
        return "";
}

debug (UseQtdDebug)
{
    debug (QtdVerbose)
    {
        import
            std.stdio,
            std.string;
    }

    final shared class QtdDebug
    {
        enum MessageType
        {
            info,
            warning,
            error
        }

        private
        {
            static immutable msgTypeStrs = ["Info", "Warning", "Error"];
            int wrapperCount_;
            int nativeDeletedCount_;

            this() {}
        }

        string wrapperToString(QtdObject wrapper)
        {
            static assert (QtdObjectFlags.sizeof == ubyte.sizeof);
            auto flags = wrapper.qtdFlags;
            return format("%s (nativeId: %s, this ptr: %s, flags: %b)"
                , wrapper, wrapper.qtdNativeId
                , cast(void*)wrapper, *cast(ubyte*)&flags);
        }

        void onWrapperConstructed(QtdObject wrapper)
        {
            info("QtdObject constructed: " ~ wrapperToString(wrapper));
            wrapperCount_++;
        }

        void onWrapperDestruction(QtdObject wrapper)
        {
            info("Entering QtdObject destructor: " ~ wrapperToString(wrapper));
        }

        void onWrapperDestroyed(QtdObject wrapper)
        {
            info(format("Leaving QtdObject destructor (dId: %s)",  cast(void*)wrapper));
            wrapperCount_--;
        }

        void onNativeDeleted(QtdObject wrapper)
        {
            info(format("Native object deleted (dId: %s)", cast(void*)wrapper));
            nativeDeletedCount_++;
        }

        void onObjectOwnershipChanged(QtdObject wrapper)
        {
            info("Object ownership changed: " ~ wrapperToString(wrapper));
        }

        void onDeletingWrapperFromNative(QtdObject wrapper)
        {
            info(format("Wrapper deletion initiated from C++ (wrapper id: %s)", cast(void*)wrapper));
        }

        @property int wrapperCount()
        {
            return wrapperCount_;
        }

        @property int nativeDeletedCount()
        {
            return nativeDeletedCount_;
        }

        void reset()
        {
            wrapperCount_ = 0;
            nativeDeletedCount_ = 0;
        }

        static void info(lazy string msg)
        {
            message(msg, MessageType.info);
        }

        static void warning(lazy string msg)
        {
            message(msg, MessageType.warning);
        }

        static void error(lazy string msg)
        {
            message(msg, MessageType.error);
        }

        static void message(lazy string msg, MessageType msgType = MessageType.info)
        {
            // The check is deliberately placed here and not at the call sites.
            // For simplicity, there are only two levels of debug verbosity:
            // verbose and silent.
            debug (QtdVerbose)
                writefln("[QtD %s] %s",  msgTypeStrs[msgType], msg);
        }
    }

    private shared QtdDebug _qtdDebug;
    static QtdDebug qtdDebug()
    {
        return _qtdDebug;
    }

    shared static this()
    {
        _qtdDebug = new QtdDebug;
    }
}

