[#--noinspection ALL--]
[#import "_macros.ftl" as global/]
/*
* Copyright (c) 2019, FusionAuth, All Rights Reserved
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
* either express or implied. See the License for the specific
* language governing permissions and limitations under the License.
*/

import IRESTClient from "./IRESTClient"
import DefaultRESTClientBuilder from "./DefaultRESTClientBuilder";
import IRESTClientBuilder from "./IRESTClientBuilder";
import ClientResponse from "./ClientResponse";

export class FusionAuthClient {

  public clientBuilder: IRESTClientBuilder = new DefaultRESTClientBuilder();

  constructor(public apiKey: string, public host: string) {
  }

[#-- @formatter:off --]
[#list apis as api]
  /**
  [#list api.comments as comment]
   * ${comment}
  [/#list]
   *
  [#list api.params![] as param]
    [#if !param.constant??]
   * @param {${global.optional(param, "ts")}${global.convertType(param.javaType, "ts")}} ${param.name} ${param.comments?join("\n   *    ")}
    [/#if]
  [/#list]
   * @returns {Observable<ClientResponse<${global.convertType(api.successResponse, "ts")}>>}
   */
  [#assign parameters = global.methodParameters(api, "ts")/]
  ${api.methodName}(${parameters}): Observable<ClientResponse<${global.convertType(api.successResponse, "ts")}>> {
    return this.start()
  [#if api.method == "post" && !global.hasBodyParam(api.params![])]
        .withHeader('Content-Type', 'text/plain')
  [/#if]
        .withUri('${api.uri}')
  [#if api.authorization??]
        .withAuthorization(${api.authorization?replace('\"', '\'')})
  [/#if]
  [#list api.params![] as param]
    [#if param.type == "urlSegment"]
        .withUriSegment(${(param.constant?? && param.constant)?then(param.value, param.name)})
    [#elseif param.type == "urlParameter"]
        .withParameter('${param.parameterName}', ${(param.constant?? && param.constant)?then(param.value, param.name)})
    [#elseif param.type == "body"]
        .withJSONBody(${param.name})
    [/#if]
  [/#list]
        .withMethod("${api.method?upper_case}")
        .go<${global.convertType(api.successResponse, "ts")}>();
  }

[/#list]
[#-- @formatter:on --]

  /* ===================================================================================================================
   * Private methods
   * ===================================================================================================================*/

  /**
   * creates a rest client
   *
   * @returns {IRestClient} The RESTClient that will be used to call.
   * @private
   */
  private start(): IRESTClient {
    return this.clientBuilder.build(this.host).withAuthorization(this.apiKey);
  }
}

[#macro printType type]
  [#if type.type??]
    ${global.convertType(type.type, "ts")}[#if type.typeArguments?has_content]<[#list type.typeArguments as typeArgument][@printType typeArgument/][#sep], [/#sep][/#list]>[/#if][#if type.extends??] extends [#list type.extends as extends][@printType extends/][#sep], [/#sep][/#list][/#if][#t]
  [#else]
    ${type.name}[#if type.extends??] extends [#list type.extends as extends][@printType extends/][#sep], [/#sep][/#list][/#if][#t]
  [/#if]
[/#macro]

[#-- @formatter:off --]
[#list domain?sort_by("type") as d]
[#if d.description??]${d.description}[/#if][#t]
[#if d.fields??]
[#-- Use interface here because classes require the correct order for declaration if it extends something --]
[#-- Interfaces are also only for type checking so they can result in smaller compiled code --]
export interface [@printType d/] {
  [#list d.fields?keys?sort as fieldName]
  [#assign field = d.fields[fieldName]/]
  [#if field.description??]${field.description}[/#if][#t]
  ${fieldName}?: [@printType field/];
  [/#list]
}
[#else]
export enum ${d.type} {
  [#list d.enum as value]
    [#if global.needsConverter(d)]
  ${value.name}: "${(value.args![])[0]!value.name}"[#sep],[/#sep]
    [#else]
  ${value.name!value}: "${value.name!value}"[#sep],[/#sep]
    [/#if]
  [/#list]
}
[/#if]

[/#list]
[#-- @formatter:on --]
