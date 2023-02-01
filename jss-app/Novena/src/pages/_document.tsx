/* eslint-disable @next/next/no-document-import-in-page */
import Document, {
  DocumentContext,
  DocumentInitialProps,
  Html,
  Main,
  NextScript,
  Head,
} from 'next/document';

class NovenaDocument extends Document {
  static async getInitialProps(ctx: DocumentContext): Promise<DocumentInitialProps> {
    const initialProps = await Document.getInitialProps(ctx);

    return initialProps;
  }

  render(): JSX.Element {
    return (
      <Html>
        <Head>
          <link
            href="https://fonts.googleapis.com/css2?family=Jost:wght@500;600;700&family=Open+Sans:wght@400;500&display=swap"
            rel="stylesheet"
          ></link>
        </Head>
        <body id="novena-body">
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}

export default NovenaDocument;
