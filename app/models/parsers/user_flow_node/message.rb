class Parsers::UserFlowNode::Message

  def self.can_handle? params
    raise "Subclasses must define this message"
  end

  def self.for application, parent_step, action, params
    (SuitableClassFinder.find_direct_subclass_of self,
      suitable_for: params,
      if_found: lambda{ | message_class |
        message_class.new application, parent_step, action, params
      },
      if_none: lambda{ | finder |
        nil
      }
    )
  end

  def name
    raise "Subclasses must define this message"
  end

  def equivalent_flow
    raise "Subclasses must define this message"
  end

  def capture_flow
    equivalent_flow
  end
end