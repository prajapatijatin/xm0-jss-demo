import { Text, TextField, withDatasourceCheck } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
interface ContactItemProp {
  displayName: string;
  id: string;
  fields: {
    Icon: TextField;
    Label: TextField;
    Text: TextField;
  };
}
type GetInTouchProps = ComponentProps & {
  fields: {
    Heading: TextField;
    ContactItems: ContactItemProp[];
  };
};
const GetInTouch = (props: GetInTouchProps): JSX.Element => {
  return (
    <>
      <div className="col-lg-3 col-md-6 col-sm-6">
        <div className="widget widget-contact mb-5 mb-lg-0">
          <Text field={props.fields.Heading} tag="h4" className="text-capitalize mb-3" />
          <div className="divider mb-4"></div>
        </div>
        {props.fields.ContactItems.map((cI) => (
          <div className="footer-contact-block mb-4" key={cI.id}>
            <div className="icon d-flex align-items-center">
              <i className={cI.fields.Icon.value}></i>
              <Text field={cI.fields.Label} tag="span" className="h6 mb-0"></Text>
            </div>
            <Text field={cI.fields.Text} tag="h4" className="mt-2"></Text>
          </div>
        ))}
      </div>
    </>
  );
};

export default withDatasourceCheck()<GetInTouchProps>(GetInTouch);
