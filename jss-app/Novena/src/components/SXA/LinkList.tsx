import React from 'react';
import { Link as JssLink, Text, LinkField, TextField } from '@sitecore-jss/sitecore-jss-nextjs';

type ResultsFieldLink = {
  field: {
    link: LinkField;
  };
};

interface Fields {
  data: {
    datasource: {
      children: {
        results: ResultsFieldLink[];
      };
      field: {
        title: TextField;
      };
    };
  };
}

type LinkListProps = {
  params: { [key: string]: string };
  fields: Fields;
};

type LinkListItemProps = {
  key: string;
  index: number;
  total: number;
  field: LinkField;
};

const LinkListItem = (props: LinkListItemProps) => {
  let className = `item${props.index}`;
  className += (props.index + 1) % 2 == 0 ? ' even' : ' odd';
  if (props.index == 0) {
    className += ' first';
  }
  if (props.index + 1 == props.total) {
    className += ' last';
  }
  return (
    <li className={className}>
      <div className="field-link">
        <JssLink field={props.field} />
      </div>
    </li>
  );
};

export const Default = (props: LinkListProps): JSX.Element => {
  const datasource = props.fields?.data?.datasource;
  //   const styles = `component link-list ${props.params.styles}`.trimEnd();
  const styles = `col-lg-2 col-mg-6 col-sm-6`;

  if (datasource) {
    const list = datasource.children.results
      .filter((element: ResultsFieldLink) => element?.field?.link)
      .map((element: ResultsFieldLink, key: number) => (
        <LinkListItem
          index={key}
          key={`${key}${element.field.link}`}
          total={datasource.children.results.length}
          field={element.field.link}
        />
      ));

    return (
      <div className={styles}>
        <div className="widget mb-5 mb-lg-0">
          <Text tag="h4" className="text-capitalize mb-3" field={datasource?.field?.title} />
          <div className="divider mb-4"></div>
          <ul className="list-unstyled footer-menu lh-35">{list}</ul>
        </div>
      </div>
    );
  }

  return (
    <div className={styles}>
      <div className="component-content">
        <h3>Link List</h3>
      </div>
    </div>
  );
};
