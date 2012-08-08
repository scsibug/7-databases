require 'time'

import 'org.apache.hadoop.hbase.client.HTable'
import 'org.apache.hadoop.hbase.client.Put'
import 'javax.xml.stream.XMLStreamConstants'

def jbytes(*args)
  args.map { |arg| arg.to_s.to_java_bytes }
end

factory = javax.xml.stream.XMLInputFactory.newInstance
reader = factory.createXMLStreamReader(java.lang.System.in)

document = nil
buffer = nil
count = 0

table = HTable.new(@hbase.configuration,'wiki')
table.setAutoFlush(false)

while reader.has_next
  type = reader.next

  if type == XMLStreamConstants::START_ELEMENT
    case reader.local_name
    when 'page' then document = {}
    when /title|timestamp|username|comment|text/ then buffer = []
    end

  elsif type == XMLStreamConstants::CHARACTERS
    buffer << reader.text unless buffer.nil?

  elsif type == XMLStreamConstants::END_ELEMENT
    
    case reader.local_name
      when /title|timestamp|username|comment|text/
      document[reader.local_name] = buffer.join
when 'revision'
      key = document['title'].to_java_bytes
      ts = (Time.parse document['timestamp'] ).to_i

      p = Put.new(key, ts)
      p.add( *jbytes("text", "", document['text'] ) )
      p.add( *jbytes("revision", "author", document['username'] ) )
      p.add( *jbytes("revision", "comment", document['comment'] ) )
      table.put(p)
      count += 1
      table.flushCommits() if count % 10 == 0
      if count % 500 == 0
        puts "#{count} records inserted (#{document['title']})"
      end
    end
  end
end

table.flushCommits()
exit
