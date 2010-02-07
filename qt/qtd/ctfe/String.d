/**
 * CTFE String routines.
 * 
 * Authors: Daniel Keep <daniel.keep@gmail.com>
 * Copyright: See LICENSE.
 */
module qt.qtd.ctfe.String;

import Integer = qt.qtd.ctfe.Integer;

private
{
    const HEX_CHARS = "0123456789abcdef";
}

/**
 * Escapes a string into an equivalent string literal.
 * 
 * Params:
 *     str = string to escape.
 *     aggressive = if set, the function will escape all non-printing
 *                  characters, non-space whitespace and newlines.  Defaults
 *                  to true.
 * Returns:
 *      Escaped string literal.
 */
string escape_ctfe(string str, bool aggressive=true)
{
    string head = "";
    
    foreach( i,c ; str )
    {
        if( c == '"' || c == '\\' || c == '\0' )
        {
            head = "\""~str[0..i];
            str = str[i..$];
            break;
        }
        
        if( aggressive )
        {
            if( c < 0x20 || c == 0x7f )
            {
                head = "\""~str[0..i];
                str = str[i..$];
                break;
            }
        }
    }
    
    if( head.length == 0 )
        return "\"" ~ str ~ "\"";
    
    string tail = "";
    
    foreach( c ; str )
    {
        if( c == '"' )
            tail ~= `\"`;
        
        else if( c == '\\' )
            tail ~= "\\\\";
        
        else if( c == '\0' )
            tail ~= `\0`;
        
        else if( aggressive )
        {
            switch( c )
            {                    
                case '\?':
                    tail ~= `\?`;
                    break;
                    
                case '\a':
                    tail ~= `\a`;
                    break;
                    
                case '\b':
                    tail ~= `\b`;
                    break;
                    
                case '\f':
                    tail ~= `\f`;
                    break;
                    
                case '\n':
                    tail ~= `\n`;
                    break;
                    
                case '\r':
                    tail ~= `\r`;
                    break;
                    
                case '\t':
                    tail ~= `\t`;
                    break;
                    
                case '\v':
                    tail ~= `\v`;
                    break;

                default:
                    if( c < 0x20 || c == 0x75 )
                    {
                        tail ~= `\x`;
                        tail ~= HEX_CHARS[c/0xf];
                        tail ~= HEX_CHARS[c&0xf];
                    }
                    else
                        tail ~= c;
            }
        }
        else
            tail ~= c;
    }
    
    return head ~ tail ~ "\"";
}

version( Unittest )
{
    static assert( escape_ctfe("abc") == "\"abc\"" );
    static assert( escape_ctfe("a\"c") == "\"a\\\"c\"" );
}

/**
 * Turns an array of bytes into a hexadecimal string.
 * 
 * Params:
 *     arr = array to hexify.
 *     grouping = if non-zero, specifies after how many bytes to insert a
 *                space.
 * Returns:
 *      String of hex bytes.
 */

string hexify_ctfe(ubyte[] arr, int grouping = 0)
{
    string r = "";
    int bytes = grouping;
    foreach( b ; arr )
    {
        if( bytes == 0 && grouping > 0 )
        {
            r ~= ' ';
            bytes = grouping;
        }

        auto bh = b/16;
        auto bl = b&15;
        
        assert( bh < 16 );
        assert( bl < 16 );
        
        r ~= HEX_CHARS[bh];
        r ~= HEX_CHARS[bl];
        
        if( grouping > 0 )
            -- bytes;
    }
    return r;
}

/// ditto

string hexify_ctfe(string arr, int grouping = 0)
{
    string r = "";
    int bytes = grouping;
    foreach( b ; arr )
    {
        if( bytes == 0 && grouping > 0 )
        {
            r ~= ' ';
            bytes = grouping;
        }

        auto bh = b/16;
        auto bl = b&15;
        
        assert( bh < 16 );
        assert( bl < 16 );
        
        r ~= HEX_CHARS[bh];
        r ~= HEX_CHARS[bl];
        
        if( grouping > 0 )
            -- bytes;
    }
    return r;
}

version( Unittest )
{
    static const ubyte[] DATA_1 = [0x00,0x01,0x02,0x03];
    static const ubyte[] DATA_2 = [0x0f,0x10,0xef,0xf0];

    static assert( hexify_ctfe(DATA_1) == "00010203" );
    static assert( hexify_ctfe(DATA_2) == "0f10eff0" );
    
    static assert( hexify_ctfe(DATA_1, 1) == "00 01 02 03" );
    static assert( hexify_ctfe(DATA_2, 1) == "0f 10 ef f0" );
    
    static assert( hexify_ctfe(DATA_1, 2) == "0001 0203" );
    static assert( hexify_ctfe(DATA_2, 2) == "0f10 eff0" );
    
    static assert( hexify_ctfe(DATA_1, 4) == "00010203" );
    static assert( hexify_ctfe(DATA_2, 4) == "0f10eff0" );
}

/**
 * Pads a string.  padl adds padding to the left, padr adds it to the right.
 * Params:
 *     str = string to pad.
 *     len = length to pad to.
 *     padding = character to use for padding.  Defaults to space.
 * Returns:
 *      padded string.
 */

string padl_ctfe(string str, int len, char padding = ' ')
{
    while( str.length < len )
        str = padding ~ str;
    return str;
}

/// ditto

string padr_ctfe(string str, int len, char padding = ' ')
{
    while( str.length < len )
        str ~= padding;
    return str;
}

version( Unittest )
{
    static assert( padl_ctfe("abc", 2) == "abc" );
    static assert( padl_ctfe("abc", 3) == "abc" );
    static assert( padl_ctfe("abc", 4) == " abc" );
    static assert( padl_ctfe("abc", 4, 'x') == "xabc" );

    static assert( padr_ctfe("abc", 2) == "abc" );
    static assert( padr_ctfe("abc", 3) == "abc" );
    static assert( padr_ctfe("abc", 4) == "abc " );
    static assert( padr_ctfe("abc", 4, 'x') == "abcx" );
}

/**
 * Returns the tail of a string after a given splitting character.  The Rev
 * variant returns the tail after the last instance of the splitting
 * character.
 */

string tail_ctfe(string str, char split)
{
    foreach( i,c ; str )
    {
        if( c == split )
            return str[i+1..$];
    }
    return str;
}

/// ditto

string tailRev_ctfe(string str, char split)
{
    foreach_reverse( i,c ; str )
    {
        if( c == split )
            return str[i+1..$];
    }
    return str;
}

/**
 * Determines whether a character is valid in an identifier in a
 * non-initial position.
 *
 * Does not support the full range of valid D identifier characters.
 */

bool isIdentChar_ctfe(char c)
{
    return ('a' <= c && c <= 'z')
        || ('A' <= c && c <= 'Z')
        || ('0' <= c && c <= '9')
        || (c == '_');
}

/**
 * Determines whether a character is valid in an identifier in an
 * initial position.
 *
 * Does not support the full range of valid D identifier characters.
 */

bool isIdentStartChar_ctfe(char c)
{
    return ('a' <= c && c <= 'z')
        || ('A' <= c && c <= 'Z')
        || (c == '_');
}

/**
 * Returns a line spec suitable for mixing in.  This can be used with string
 * mixins to ensure compile errors appear on the "correct" line in the source.
 */

string linespec_ctfe(string file, long line)
{
    return "#line "~Integer.format_ctfe(line)~" \"" ~ file ~ "\"\n";
}

