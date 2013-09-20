package stronzi;
import haxe.macro.Context;
import haxe.macro.Expr;

class FakeEnum{
  public static function buildInts(?start = 0, subName = null){
    var src = Context.getBuildFields();
    var fields = [];
    for(f in src) switch(f.kind){
      case FVar(null,null):
        var idx = start++;
        fields.push({name:f.name, value:{expr:EConst(CInt('$idx')), pos:f.pos}, pos:f.pos});
      case _: throw 'impossible';
    }
    def(fields, subName);
    return src;
  }

  public static function build(?subName = null){
    var src = Context.getBuildFields();
    var fields = [];
    for(f in src) switch(f.kind){
      case FVar(null,null):
        var value = null, gotMeta = false;
        for(m in f.meta)
          if(m.name == 'v' || m.name == ':v'){
            if(m.params.length == 1) value = m.params[0];
            gotMeta = true;
            break;
          }
        if(!gotMeta) Context.warning('Variant ${f.name} needs @v', f.pos);
        fields.push({name:f.name, value:value, pos:f.pos});
      case _: throw 'impossible';
    }
    def(fields, subName);
    return src;
  }

  static inline function def(fields:Array<{name:String, value:Expr, pos:Position}>, subName){
    var pos = Context.currentPos();
    var pack, name;
    switch(Context.getLocalType()){
      case TEnum(ref, _):
        var t = ref.get();
        pack = t.pack;
        name = t.name;
      case _: throw 'impossible';
    }
    if(subName == null) subName = name+'Fake';
    var srcFullName = pack.length == 0 ? name : pack.join('.')+'.'+name;
    var sub = {
      pos:pos,
      params:[],
      pack:pack,
      name:subName,
      meta:[
        {pos:pos, name:':native', params:[{pos:pos, expr:EConst(CString(srcFullName))}]},
      ],
      kind:TDClass(),
      isExtern:false,
      fields:[for(f in fields){
        kind:FVar(null, f.value),
        meta:[],
        name:f.name,
        doc:null,
        pos:f.pos,
        access:[AStatic, APublic],
      }],
    };
    Context.defineType(sub);
  }
}
