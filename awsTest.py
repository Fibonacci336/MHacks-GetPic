from amazon.api import AmazonAPI

amazon = AmazonAPI("AKIAJEXNJSWHTI5YMVDQ", "iOiwcsWeR0+Fu4SH2EGlqv7T6MKBD2mOsqMrNcJ6", "getpic-20")
products = amazon.search_n(1, Keywords='kindle', SearchIndex='All')

print(len(products))


